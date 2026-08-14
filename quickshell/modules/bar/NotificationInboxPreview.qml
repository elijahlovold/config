pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.modules.theme
import qs.modules.notifications

// Missed-notification list, right-click-toggled open from NotificationBell.qml.
// Same anchored-under-the-pill shape as CalendarPreview.qml/MusicPreview.qml -
// entries are plain snapshots from NotificationsStore, most recent first, no
// per-entry actions (the underlying dbus notification/sender is long gone by
// the time something lands here). Clearing the whole inbox is a right-click
// on the bell itself, not done from in here.
PopupWindow {
    id: popup

    required property Item anchorItem

    readonly property alias hovered: cardHoverHandler.hovered
    readonly property int maxListHeight: 360

    anchor {
        item: popup.anchorItem
        edges: Edges.Bottom
        gravity: Edges.Bottom
        margins.top: 0
    }

    visible: true
    implicitWidth: 320
    implicitHeight: card.height
    color: "transparent"

    Rectangle {
        id: card
        width: popup.implicitWidth
        height: (list.count > 0 ? Math.min(list.contentHeight, popup.maxListHeight) + 24 : 60)
        radius: 8
        color: Theme.pillBg
        border.color: Theme.pillBorder
        border.width: 1

        HoverHandler { id: cardHoverHandler }

        Text {
            visible: list.count === 0
            anchors.centerIn: parent
            text: "No notifications"
            color: Theme.dimText
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }

        ListView {
            id: list
            visible: count > 0
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12
            clip: true
            model: NotificationsStore.inbox

            delegate: Item {
                id: entryDelegate
                required property var modelData

                width: list.width
                height: entryCol.height

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -6
                    radius: 6
                    color: Theme.hoverBg
                    visible: entryHover.hovered
                }

                HoverHandler {
                    id: entryHover
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onClicked: NotificationsStore.removeEntry(entryDelegate.modelData.id)
                }

                Column {
                    id: entryCol
                    width: parent.width
                    spacing: 2

                    Row {
                        width: parent.width
                        spacing: 6

                        IconImage {
                            width: 14
                            height: 14
                            source: entryDelegate.modelData.appIcon
                            visible: entryDelegate.modelData.appIcon !== ""
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: entryDelegate.modelData.appName
                            color: Theme.dimText
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 3
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Qt.formatDateTime(new Date(entryDelegate.modelData.time), "hh:mm")
                            color: Theme.dimText
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 3
                        }
                    }

                    Text {
                        width: parent.width
                        text: entryDelegate.modelData.summary
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 1
                        font.bold: true
                        wrapMode: Text.Wrap
                    }

                    Text {
                        width: parent.width
                        visible: entryDelegate.modelData.body !== ""
                        text: entryDelegate.modelData.body
                        color: Theme.dimText
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 2
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
    }
}
