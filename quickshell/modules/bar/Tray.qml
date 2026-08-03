pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects
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
                id: trayIcon
                anchors.fill: parent
                source: trayDelegate.modelData.icon
                visible: false
                smooth: false // avoid blur re-rendered through the effect chain below
            }

            // Tray icons come in full-color from whatever app/theme provided
            // them. A flat single-color recolor (source alpha filled solid
            // with Theme.accent) loses all shading - fine for line-art
            // symbolic icons, but many tray icons are just filled circles/
            // blobs with no interesting silhouette, so a flat fill makes
            // them all identical indistinguishable dots. Desaturate first,
            // then multiply the grayscale result by Theme.accent (duotone
            // via multiply, not a linear alpha blend) - black stays exactly
            // black regardless of accent, white becomes exactly the accent
            // color, and everything between scales proportionally.
            Desaturate {
                id: desaturatedTrayIcon
                anchors.fill: trayIcon
                source: trayIcon
                visible: false
                smooth: false
                desaturation: 1.0
            }

            Rectangle {
                id: accentFill
                anchors.fill: trayIcon
                color: Theme.accent
                visible: false
            }

            Blend {
                anchors.fill: trayIcon
                source: desaturatedTrayIcon
                foregroundSource: accentFill
                mode: "multiply"
            }

            ToolTip.visible: trayDelegate.containsMouse && trayDelegate.modelData.tooltipTitle.length > 0
            ToolTip.text: trayDelegate.modelData.tooltipTitle
            ToolTip.delay: 400
        }
    }
}
