import Quickshell
import Quickshell.Services.Notifications

// Entry point: instantiate once from shell.qml. Owns the dbus
// org.freedesktop.Notifications server and the list of currently-visible
// popups; NotificationPopups.qml only ever renders whatever's in
// root.popups, it never touches the server directly.
//
// Only one process can own the org.freedesktop.Notifications dbus name at a
// time - if a separate daemon (mako/dunst/swaync/etc) is already running,
// this server will fail to register and nothing will show up.
Scope {
    id: root

    property var popups: []
    property int _nextInboxId: 0

    function removePopup(notification) {
        root.popups = root.popups.filter(n => n !== notification);
    }

    // Only a silent timeout (Expired) counts as "missed" and earns an inbox
    // entry - Dismissed/CloseRequested both mean the user (or the sending
    // app) already dealt with it, so there's nothing left to triage later.
    function handlePopupClosed(notification, reason) {
        if (reason === NotificationCloseReason.Expired) {
            NotificationsStore.addEntry({
                id: root._nextInboxId++,
                appName: notification.appName,
                appIcon: notification.appIcon,
                summary: notification.summary,
                body: notification.body,
                urgency: notification.urgency,
                time: Date.now(),
            });
        }
        root.removePopup(notification);
    }

    NotificationServer {
        id: server

        // keepOnReload matters a lot here specifically because this repo
        // hot-reloads on every save - without it, saving a tweak to a popup
        // skin would drop the dbus registration and lose in-flight
        // notifications.
        keepOnReload: true

        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false
        bodyImagesSupported: false
        imageSupported: true
        persistenceSupported: false

        onNotification: notification => {
            notification.tracked = true;
            notification.closed.connect(reason => root.handlePopupClosed(notification, reason));
            root.popups = [...root.popups, notification];
        }
    }

    NotificationPopups {
        popups: root.popups
    }
}
