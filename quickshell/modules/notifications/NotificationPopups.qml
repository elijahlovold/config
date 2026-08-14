pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.modules.common
import qs.modules.theme

// Single panel window (pinned to the primary output, same as
// DesktopOverlayWindow) stacking every currently-tracked popup top to
// bottom in the top-right corner. Content-driven size: height tracks
// list.contentHeight so the window never reserves more space than the
// current popups need.
PanelWindow {
    id: root

    required property var popups

    screen: MonitorRoles.primaryScreen()

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:notifications"
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    color: "transparent"

    anchors {
        top: true
        right: true
    }
    margins {
        top: Theme.barHeight + 8
        right: 8
    }

    implicitWidth: 340
    implicitHeight: Math.min(list.contentHeight, screen.height * 0.8)

    ListView {
        id: list
        anchors.fill: parent
        spacing: 8
        model: root.popups
        interactive: false

        add: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 150 }
        }
        remove: Transition {
            NumberAnimation { property: "opacity"; to: 0; duration: 150 }
        }
        displaced: Transition {
            NumberAnimation { property: "y"; duration: 150 }
        }

        delegate: NotificationCard {
            id: delegateRoot
            required property var modelData
            width: list.width
            notification: delegateRoot.modelData
        }
    }
}
