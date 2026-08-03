pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.modules.common

// Chip-per-workspace inside a shared pill (no per-workspace border box
// anymore) - focused/urgent get a filled chip, active-elsewhere gets
// colored text only, everything else stays dim.
Pill {
    id: root

    required property ShellScreen screen
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)

    spacing: 4
    horizontalPadding: 6

    Repeater {
        model: Hyprland.workspaces

        delegate: Rectangle {
            id: wsDelegate

            required property HyprlandWorkspace modelData
            readonly property bool onThisMonitor: wsDelegate.modelData.monitor === root.monitor

            visible: wsDelegate.onThisMonitor
            width: wsDelegate.onThisMonitor ? Math.max(18, label.implicitWidth + 8) : 0
            height: 18
            radius: 5
            color: wsDelegate.modelData.urgent ? Theme.urgentWorkspace
                 : wsDelegate.modelData.focused ? Theme.focusedWorkspace
                 : "transparent"

            Text {
                id: label
                anchors.centerIn: parent
                text: wsDelegate.modelData.name || wsDelegate.modelData.id
                color: (wsDelegate.modelData.urgent || wsDelegate.modelData.focused) ? "#0A0A0C"
                     : wsDelegate.modelData.active ? Theme.activeWorkspace
                     : Theme.dimText
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 2
                font.bold: wsDelegate.modelData.focused
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch(`hl.dsp.focus({workspace = ${wsDelegate.modelData.id}})`)
            }
        }
    }
}
