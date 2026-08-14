pragma Singleton
import QtQuick
import Quickshell
import qs.modules.theme

// Transient (never persisted) visibility state for the freehand drawing
// overlay - unlike ReticleStore/DesktopOverlayStore there's nothing worth
// saving to disk. The whole point of this tool is that toggling off
// discards every stroke: DrawWindow.qml is torn down and rebuilt blank each
// time via Draw.qml's Loader{active: DrawStore.visible}, same lifecycle
// ReticleWindow/DesktopOverlayWindow already use - the difference is there's
// no FileView-backed state to restore on the next open, so a fresh
// DrawCanvas just starts empty.
Singleton {
    id: root

    property bool visible: false

    // Pen state and the clear trigger live here (not on DrawCanvas) so
    // DrawPalette.qml - a sibling item, not a parent/child of the canvas -
    // can read and drive them too.
    readonly property var colors: ["#ff2d2d", "#39ff14", "#00e5ff", "#ffe234", "#ffffff"]
    // Second palette row - the shell's actual wallust palette, so it's easy
    // to annotate in a color that blends with the current theme instead of
    // always reaching for the high-contrast row above. Stays reactive to
    // Theme's bindings, so a `wallust run` re-theme updates this live.
    readonly property var themeColors: [Theme.color1, Theme.color2, Theme.color3, Theme.color4, Theme.color5, Theme.color6, Theme.color7, Theme.color8]
    readonly property var widths: [2, 4, 7]

    property color penColor: root.colors[0]
    property real penWidth: root.widths[1]

    signal clearRequested

    function setVisible(v) {
        root.visible = v;
    }

    function toggleVisible() {
        setVisible(!root.visible);
    }

    function setPenColor(c) {
        root.penColor = c;
    }

    function cyclePenWidth() {
        var idx = root.widths.indexOf(root.penWidth);
        root.penWidth = root.widths[(idx + 1) % root.widths.length];
    }

    function requestClear() {
        root.clearRequested();
    }
}
