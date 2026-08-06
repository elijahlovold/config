pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.modules.theme

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barRoot

            required property ShellScreen modelData
            screen: barRoot.modelData

            // Mirrors the old i3 bar {} blocks: DP-2 (was DisplayPort-1) got the
            // full i3status-rust config + tray, DP-1 (was DisplayPort-0) got the
            // short config. HDMI-A-1 (was HDMI-A-0) is currently a disabled output
            // but kept configured for when it's re-enabled.
            readonly property bool full: barRoot.modelData.name !== "DP-1"
            readonly property bool showTray: barRoot.modelData.name === "DP-2"

            anchors {
                top: true
                left: true
                right: true
            }
            implicitHeight: Theme.barHeight
            color: "transparent"
            exclusionMode: ExclusionMode.Auto
            WlrLayershell.namespace: "quickshell:bar"

            Workspaces {
                id: workspacesItem
                screen: barRoot.modelData
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.bottom: parent.bottom
                // anchors.verticalCenter: parent.verticalCenter
            }

            // Hugs the right edge normally (same as a plain anchors.right),
            // but never slides further left than just past Workspaces - on
            // a narrow monitor where RightCluster's natural content is
            // wider than the room available, it stays put there instead of
            // sliding left and rendering over/under the workspace pill.
            // Whatever doesn't fit past that point runs off the right edge
            // of the bar's own surface instead (invisible past the window's
            // bounds) rather than covering Workspaces.
            RightCluster {
                id: rightCluster
                full: barRoot.full
                showTray: barRoot.showTray
                anchors.bottom: parent.bottom
                // anchors.verticalCenter: parent.verticalCenter
                x: Math.max(workspacesItem.x + workspacesItem.width + 8, parent.width - rightCluster.width - 8)
            }
        }
    }
}
