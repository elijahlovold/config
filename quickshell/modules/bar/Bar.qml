pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.modules.theme
import qs.modules.common

Scope {
    // Quickshell's incremental Hyprland state tracking misses workspace-
    // altering actions that don't change global focus - e.g. win+N
    // (movecurrentworkspacetomonitor) fires Hyprland's moveworkspacev2
    // event, but the workspace that was displaced on the destination
    // monitor keeps reporting stale active/focused flags until some
    // unrelated workspace-focus event forces a resync. Force one directly
    // on the event that's known to fall through. Single Connections here
    // (Scope is instantiated once, unlike the per-monitor Variants below).
    Connections {
        target: Hyprland

        function onRawEvent(event: HyprlandEvent) {
            if (event.name === "moveworkspacev2" || event.name === "moveworkspace") {
                Hyprland.refreshWorkspaces();
                Hyprland.refreshMonitors();
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barRoot

            required property ShellScreen modelData
            screen: barRoot.modelData

            // Mirrors the old i3 bar {} blocks: the primary monitor got the full
            // i3status-rust config + tray, DP-1 (was DisplayPort-0) got the short
            // config. DP-1 is the only output ever special-cased by name - whichever
            // monitor is playing "primary" (DP-2 in dual mode, HDMI-A-1 when solo -
            // see toggle-monitors) gets the full treatment, so both get the same
            // bar layout without hardcoding either name.
            readonly property bool full: !MonitorRoles.isSecondary(barRoot.modelData)
            readonly property bool showTray: barRoot.full

            anchors {
                top: true
                left: true
                right: true
            }
            implicitHeight: Theme.barHeight
            color: "transparent"
            exclusionMode: ExclusionMode.Auto
            WlrLayershell.namespace: "quickshell:bar"
            // OnDemand (not the None default) - needed so popups spawned
            // from this window (e.g. UnitToolsPreview's TextInputs) can
            // ever receive real Wayland keyboard input at all. OnDemand
            // only actually takes focus when something inside requests it
            // (forceActiveFocus()), same reasoning as KeytreeWindow.qml -
            // it won't steal focus from other apps just by existing.
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

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
