pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.modules.theme

// One popup card. Deliberately plain right now (rounded rect, text,
// actions) - see modules/theme's structural-theming pattern for how this'll
// grow per-theme skins later without touching the state below.
ClippingRectangle {
    id: root

    required property Notification notification

    readonly property string iconSource: root.notification.appIcon || root.notification.image

    readonly property var visibleActions: root.notification.actions.filter(a => a.identifier !== "default")
    readonly property var defaultAction: root.notification.actions.find(a => a.identifier === "default") ?? null

    // freedesktop spec: expire_timeout < 0 means "server default", 0 means
    // "never expire" (sender-requested, respected literally), >0 is ms.
    // Server default here is 5s, except Critical never auto-expires unless
    // the sender explicitly asked for a positive timeout.
    readonly property int effectiveTimeout: {
        if (root.notification.expireTimeout >= 0)
            return root.notification.expireTimeout;
        return root.notification.urgency === NotificationUrgency.Critical ? 0 : 5000;
    }

    implicitHeight: contentCol.y + contentCol.height + 10
    radius: 8
    color: Theme.pillBg
    border.color: Theme.pillBorder
    border.width: 1

    Rectangle {
        anchors.fill: parent
        color: Theme.hoverBg
        opacity: hoverArea.containsMouse ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    Timer {
        id: expireTimer
        interval: root.effectiveTimeout
        running: root.effectiveTimeout > 0
        onTriggered: root.notification.expire()
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: expireTimer.stop()
        onExited: {
            if (root.effectiveTimeout > 0)
                expireTimer.restart();
        }
        onClicked: {
            if (root.defaultAction)
                root.defaultAction.invoke();
            root.notification.dismiss();
        }
    }

    Column {
        id: contentCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        anchors.topMargin: 10
        spacing: 6

        Row {
            width: parent.width
            spacing: 8

            IconImage {
                id: appIcon
                width: 16
                height: 16
                source: root.iconSource
                visible: root.iconSource !== ""
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                width: parent.width - (appIcon.visible ? appIcon.width + parent.spacing : 0)
                text: root.notification.appName
                color: Theme.dimText
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 2
                elide: Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Text {
            width: parent.width
            text: root.notification.summary
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.bold: true
            wrapMode: Text.Wrap
        }

        Text {
            width: parent.width
            visible: root.notification.body !== ""
            text: root.notification.body
            color: Theme.dimText
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
            wrapMode: Text.Wrap
        }

        Row {
            width: parent.width
            spacing: 6
            visible: root.visibleActions.length > 0

            Repeater {
                model: root.visibleActions

                delegate: Rectangle {
                    id: actionButton
                    required property NotificationAction modelData

                    implicitWidth: actionLabel.width + 16
                    implicitHeight: actionLabel.height + 8
                    radius: 6
                    color: actionHover.hovered ? Theme.hoverBg : Theme.pillBg
                    border.color: Theme.pillBorder
                    border.width: 1

                    Text {
                        id: actionLabel
                        anchors.centerIn: parent
                        text: actionButton.modelData.text
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 2
                    }

                    HoverHandler {
                        id: actionHover
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            actionButton.modelData.invoke();
                            root.notification.dismiss();
                        }
                    }
                }
            }
        }
    }
}
