pragma Singleton
import QtQuick
import Quickshell

Singleton {
    // Palette lifted from the old i3 bar { colors { ... } } block, kept as-is
    // for visual continuity during the waybar -> quickshell migration.
    readonly property color background: "#CC000000"
    readonly property color focusedWorkspace: "#00dce8"
    readonly property color activeWorkspace: "#925cff"
    readonly property color inactiveWorkspace: "#3860ff"
    readonly property color urgentWorkspace: "#c40233"

    readonly property color text: "#ffffff"
    readonly property color dimText: "#888888"

    // Grouped-pill widget clusters (Pill.qml, used throughout Bar.qml).
    // Deliberately opaque-ish rather than barely-there - now that the bar
    // has no solid backing rectangle of its own, pills need to read clearly
    // over any wallpaper on their own.
    readonly property color pillBg: "#D916161C"
    readonly property color pillBorder: "#33FFFFFF"

    readonly property string fontFamily: "FiraCode Nerd Font"
    readonly property int fontSize: 14
    readonly property int barHeight: 32
}
