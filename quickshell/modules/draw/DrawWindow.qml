import QtQuick
import Quickshell
import Quickshell.Wayland

// Fullscreen freehand annotation surface. Unlike ReticleWindow.qml's
// click-through mask, this one is deliberately opaque to input everywhere -
// the whole point is capturing mouse drags to draw - so no mask override.
// WlrLayer.Overlay, same as ReticleWindow.qml, so it can annotate over a
// fullscreened game/video instead of getting hidden behind it.
PanelWindow {
    id: root

    screen: MonitorRoles.primaryScreen()

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:draw"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    color: "transparent"

    Shortcut {
        sequence: "Escape"
        onActivated: DrawStore.setVisible(false)
    }

    DrawCanvas {
        anchors.fill: parent
    }

    // Declared after DrawCanvas so it stacks on top and its PointerHandlers
    // win hit-testing over DrawCanvas's full-screen MouseArea within its
    // own small bounds - see DrawPalette.qml's own comment for why that's
    // safe to rely on.
    DrawPalette {
        // PanelWindow itself isn't a QQuickItem (it's a window wrapper), so
        // it can't satisfy an Item-typed property - contentItem is its
        // actual content Item and matches the window's own geometry since
        // it fills via the anchors above.
        boundsItem: root.contentItem
    }
}
