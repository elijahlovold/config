pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland

// Click-through WlrLayer.Bottom surface holding the clock+weather card,
// positioned anywhere on screen via DesktopOverlayStore's normalized nx/ny.
// mpvpaper (the video wallpaper player in use here) defaults to
// WlrLayer.Background, which sits below Bottom in the wlr layer-shell stack,
// so this draws on top of the wallpaper without any extra configuration.
//
// Simplified single-widget version of zesis's DesktopWidget.qml - that one
// is a generic host for an arbitrary catalog of desktop widgets (globe,
// sysmon, per-widget background/mask config); none of that applies to a
// single fixed clock+weather card.
//
// Hidden while edit mode is active - DesktopEditOverlay renders a draggable
// proxy in its place, then writes the new position/scale back to the store.
PanelWindow {
    id: root

    // Without an explicit screen, PanelWindow falls back to whichever
    // monitor currently has focus/cursor - pin it to the configured primary
    // output instead so the overlay doesn't jump monitors on reload.
    screen: Quickshell.screens.find(s => s.name === DesktopOverlayStore.primaryOutput) ?? Quickshell.screens[0]

    property real _nx: 0.5
    property real _ny: 0.5

    property real _marginLeft: _nx * Math.max(0, screen.width - implicitWidth)
    property real _marginTop: _ny * Math.max(0, screen.height - implicitHeight)

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "quickshell:desktop-overlay"

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

    mask: Region {}

    visible: !DesktopOverlayStore.editMode

    // width/height stay bound always - see modules/desktop/DesktopEditOverlay.qml's
    // matching proxy sizing for why (Loader doesn't auto-size to a plain
    // Item's implicitWidth/Height, so both loader and content read it back
    // explicitly instead of relying on that).
    Loader {
        id: contentLoader
        anchors.centerIn: parent
        sourceComponent: ClockWeatherCard {
            contentScale: DesktopOverlayStore.scale
        }
        width: item?.implicitWidth ?? 0
        height: item?.implicitHeight ?? 0
    }

    // Re-read position from store when edit mode exits (overlay may have moved us).
    Connections {
        target: DesktopOverlayStore
        function onEditModeChanged() {
            if (!DesktopOverlayStore.editMode) {
                var pos = DesktopOverlayStore.getPos();
                root._nx = pos.nx;
                root._ny = pos.ny;
            }
        }
    }

    Component.onCompleted: {
        var pos = DesktopOverlayStore.getPos();
        root._nx = pos.nx;
        root._ny = pos.ny;
    }
}
