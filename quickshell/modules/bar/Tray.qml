pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.modules.common

Row {
    id: root
    spacing: 6

    Repeater {
        model: SystemTray.items

        delegate: MouseArea {
            id: trayDelegate

            required property SystemTrayItem modelData

            width: 20
            height: 20
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor

            onClicked: mouse => {
                if (mouse.button === Qt.LeftButton)
                    trayDelegate.modelData.activate();
                else if (mouse.button === Qt.RightButton)
                    trayDelegate.modelData.secondaryActivate();
            }

            IconImage {
                anchors.fill: parent
                source: trayDelegate.modelData.icon
            }

            ToolTip.visible: trayDelegate.containsMouse && trayDelegate.modelData.tooltipTitle.length > 0
            ToolTip.text: trayDelegate.modelData.tooltipTitle
            ToolTip.delay: 400
        }
    }
}
