pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland

// Click-through WlrLayer.Overlay surface holding the aiming reticle -
// Overlay (not Bottom, unlike DesktopOverlayWindow.qml) is the one
// wlr-layer-shell layer Hyprland keeps drawn above fullscreen toplevel
// windows, which is the entire point of this widget: it must stay visible
// over a fullscreened game rather than getting covered by it.
//
// Positioned anywhere on screen via ReticleStore's normalized nx/ny, same
// pattern as DesktopOverlayWindow.qml.
PanelWindow {
    id: root

    // Without an explicit screen, PanelWindow falls back to whichever
    // monitor currently has focus/cursor - pin it to the primary output
    // instead so the overlay doesn't jump monitors on reload.
    screen: MonitorRoles.primaryScreen()

    property real _nx: 0.5
    property real _ny: 0.5

    property real _marginLeft: _nx * Math.max(0, screen.width - implicitWidth)
    property real _marginTop: _ny * Math.max(0, screen.height - implicitHeight)

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:reticle"

    anchors {
        top: true
        left: true
    }
    margins {
        top: Math.round(root._marginTop)
        left: Math.round(root._marginLeft)
    }

    implicitWidth: contentLoader.item?.implicitWidth ?? 0
    implicitHeight: contentLoader.item?.implicitHeight ?? 0

    exclusiveZone: -1
    color: "transparent"

    // Empty region = fully click-through: the reticle must never intercept
    // mouse/keyboard input meant for the fullscreen window underneath.
    mask: Region {}

    visible: !ReticleStore.editMode

    // width/height stay bound always - see modules/reticle/ReticleEditOverlay.qml's
    // matching proxy sizing for why (Loader doesn't auto-size to a plain
    // Item's implicitWidth/Height, so both loader and content read it back
    // explicitly instead of relying on that).
    Loader {
        id: contentLoader
        anchors.centerIn: parent
        sourceComponent: ReticleView {
            contentScale: ReticleStore.scale
        }
        width: item?.implicitWidth ?? 0
        height: item?.implicitHeight ?? 0
    }

    // Re-read position from store when edit mode exits (overlay may have moved us).
    Connections {
        target: ReticleStore
        function onEditModeChanged() {
            if (!ReticleStore.editMode) {
                var pos = ReticleStore.getPos();
                root._nx = pos.nx;
                root._ny = pos.ny;
            }
        }
    }

    Component.onCompleted: {
        var pos = ReticleStore.getPos();
        root._nx = pos.nx;
        root._ny = pos.ny;
    }
}
