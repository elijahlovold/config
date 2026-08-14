pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.theme
import qs.modules.notifications

// Left-click toggles the inbox preview (missed/timed-out notifications,
// see NotificationsStore); right-click clears it outright. Same
// opener-widget shape as Music.qml/Clock.qml - see CLAUDE.md's "right-click
// popup pattern" section.
Item {
    id: root

    readonly property string icon: String.fromCharCode(0xf0f3) // fa-bell
    property bool previewOpen: false

    implicitWidth: contentRow.width
    implicitHeight: contentRow.height
    width: implicitWidth
    height: implicitHeight

    Row {
        id: contentRow
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: NotificationsStore.inbox.length > 0
            text: NotificationsStore.inbox.length
            color: Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 3
            font.bold: true
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: closeTimer.stop()
        onExited: closeTimer.restart()
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                NotificationsStore.clearInbox();
            else
                root.previewOpen = !root.previewOpen;
        }
    }

    // Grace period so crossing the small gap between the pill and the
    // popup below it (or moving between the two) doesn't cause a flicker
    // close - only actually closes if neither is hovered once it fires.
    Timer {
        id: closeTimer
        interval: 250
        onTriggered: {
            if (!(previewLoader.item?.hovered ?? false))
                root.previewOpen = false;
        }
    }

    Loader {
        id: previewLoader
        active: root.previewOpen
        sourceComponent: NotificationInboxPreview {
            anchorItem: root
        }
    }

    Connections {
        target: previewLoader.item
        function onHoveredChanged() {
            if (previewLoader.item.hovered)
                closeTimer.stop();
            else
                closeTimer.restart();
        }
    }
}
