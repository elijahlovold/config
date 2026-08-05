pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.modules.common
import qs.modules.theme

// Per-workspace indicator. Structural rendering is theme-dependent (see
// ThemeManager) - each skin below is a self-contained inline Component,
// picked by skinLoader.sourceComponent. Any theme name without its own
// case here falls back to the Minimal skin, so new themes don't have to
// implement every widget's skin up front. State (screen/monitor) lives on
// the outer Item and is read directly by each skin via the `root` id -
// same pattern as PollingLabel popups (see Stator.qml's popupComponent).
Item {
    id: root

    required property ShellScreen screen
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)

    implicitWidth: skinLoader.item ? skinLoader.item.width : 0
    implicitHeight: skinLoader.item ? skinLoader.item.height : 0
    width: root.implicitWidth
    height: root.implicitHeight

    Loader {
        id: skinLoader
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        sourceComponent: {
            switch (ThemeManager.activeTheme) {
            case "Cyber":
                return cyberSkin;
            case "Glass":
                return glassSkin;
            default:
                return minimalSkin;
            }
        }
    }

    // ── Minimal (default/fallback) ───────────────────────────────────────────
    // Chip-per-workspace inside a shared pill - filled rounded rect for
    // focused/urgent, colored text only for active-elsewhere, dim otherwise.
    Component {
        id: minimalSkin

        Pill {
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
                        color: (wsDelegate.modelData.urgent || wsDelegate.modelData.focused) ? Theme.onAccentText
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
    }

    // ── Cyber ─────────────────────────────────────────────────────────────
    // Square-cornered bracket cells, no outer pill chrome, fast/snappy color
    // and width transitions - reads as raw HUD segments rather than soft pills.
    Component {
        id: cyberSkin

        Item {
            id: cyberRoot

            implicitWidth: cyberRow.width
            implicitHeight: 18
            width: cyberRoot.implicitWidth
            height: cyberRoot.implicitHeight

            Row {
                id: cyberRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Repeater {
                    model: Hyprland.workspaces

                    delegate: Rectangle {
                        id: cyberCell

                        required property HyprlandWorkspace modelData
                        readonly property bool onThisMonitor: cyberCell.modelData.monitor === root.monitor

                        visible: cyberCell.onThisMonitor
                        width: cyberCell.onThisMonitor ? Math.max(18, cyberLabel.implicitWidth + 10) : 0
                        height: 18
                        radius: 0
                        color: cyberCell.modelData.urgent ? Theme.urgentWorkspace
                             : cyberCell.modelData.focused ? Theme.focusedWorkspace
                             : "transparent"
                        border.width: cyberCell.modelData.focused ? 2 : 1
                        border.color: cyberCell.modelData.urgent ? Theme.urgentWorkspace
                                    : cyberCell.modelData.focused ? Theme.accent
                                    : Theme.dimText

                        Behavior on color {
                            ColorAnimation {
                                duration: 80
                            }
                        }
                        Behavior on border.color {
                            ColorAnimation {
                                duration: 80
                            }
                        }
                        Behavior on width {
                            NumberAnimation {
                                duration: 80
                            }
                        }

                        Text {
                            id: cyberLabel
                            anchors.centerIn: parent
                            text: cyberCell.modelData.name || cyberCell.modelData.id
                            color: (cyberCell.modelData.urgent || cyberCell.modelData.focused) ? Theme.onAccentText
                                 : cyberCell.modelData.active ? Theme.activeWorkspace
                                 : Theme.dimText
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 2
                            font.bold: cyberCell.modelData.focused
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Hyprland.dispatch(`hl.dsp.focus({workspace = ${cyberCell.modelData.id}})`)
                        }
                    }
                }
            }
        }
    }

    // ── Glass ─────────────────────────────────────────────────────────────
    // Text-only cells inside a fully-rounded translucent capsule; a single
    // shared indicator slides (slow OutCubic) to sit behind whichever cell
    // is focused, instead of each cell carrying its own fill.
    Component {
        id: glassSkin

        Rectangle {
            id: glassRoot

            readonly property int focusedIndex: {
                for (let i = 0; i < wsRepeater.count; i++) {
                    const it = wsRepeater.itemAt(i);
                    if (it && it.focused)
                        return i;
                }
                return -1;
            }

            implicitWidth: glassRow.width + 20
            implicitHeight: 24
            width: glassRoot.implicitWidth
            height: glassRoot.implicitHeight
            radius: height / 2
            color: Theme.withAlpha(Theme.pillBg, 0.5)
            border.width: 1
            border.color: Theme.withAlpha(Theme.foreground, 0.15)

            Rectangle {
                id: indicator

                visible: glassRoot.focusedIndex >= 0
                radius: height / 2
                color: Theme.withAlpha(Theme.focusedWorkspace, 0.35)
                border.width: 1
                border.color: Theme.withAlpha(Theme.focusedWorkspace, 0.7)
                y: glassRow.y - 2
                height: glassRow.height + 4
                x: glassRoot.focusedIndex >= 0 ? glassRow.x + wsRepeater.itemAt(glassRoot.focusedIndex).x - 2 : 0
                width: glassRoot.focusedIndex >= 0 ? wsRepeater.itemAt(glassRoot.focusedIndex).width + 4 : 0

                Behavior on x {
                    NumberAnimation {
                        duration: 260
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on width {
                    NumberAnimation {
                        duration: 260
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Row {
                id: glassRow
                anchors.centerIn: parent
                spacing: 8

                Repeater {
                    id: wsRepeater
                    model: Hyprland.workspaces

                    delegate: Item {
                        id: glassCell

                        required property HyprlandWorkspace modelData
                        readonly property bool onThisMonitor: glassCell.modelData.monitor === root.monitor
                        readonly property bool focused: glassCell.onThisMonitor && glassCell.modelData.focused

                        visible: glassCell.onThisMonitor
                        width: glassCell.onThisMonitor ? glassLabel.implicitWidth + 6 : 0
                        height: 18

                        Text {
                            id: glassLabel
                            anchors.centerIn: parent
                            text: glassCell.modelData.name || glassCell.modelData.id
                            color: glassCell.modelData.urgent ? Theme.urgentWorkspace
                                 : glassCell.focused ? Theme.text
                                 : glassCell.modelData.active ? Theme.activeWorkspace
                                 : Theme.dimText
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 2
                            font.bold: glassCell.focused
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Hyprland.dispatch(`hl.dsp.focus({workspace = ${glassCell.modelData.id}})`)
                        }
                    }
                }
            }
        }
    }
}
