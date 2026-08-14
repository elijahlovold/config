pragma Singleton
import QtQuick
import Quickshell

// Shell-wide notification inbox - the durable history of notifications the
// user *missed* (timed out unacknowledged), as opposed to Notifications.qml's
// own root.popups which is just the transient "currently showing" stack.
// A singleton (same pattern as ThemeManager/DesktopOverlayStore) since the
// bell icon lives in modules/bar/ while the server lives in
// modules/notifications/ - both need to read/mutate this from their own
// module.
//
// Entries are plain snapshots (appName/summary/body/... captured at receipt
// time), not live Notification references - the underlying dbus object can
// be destroyed once closed, so nothing here can call back into the sender.
Singleton {
    id: root

    property var inbox: []

    function addEntry(entry) {
        root.inbox = [entry, ...root.inbox];
    }

    function clearInbox() {
        root.inbox = [];
    }

    function removeEntry(id) {
        root.inbox = root.inbox.filter(e => e.id !== id);
    }
}
