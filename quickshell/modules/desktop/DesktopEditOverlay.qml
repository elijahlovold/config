pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.modules.common

// Full-screen drag/resize UI for the single desktop clock+weather card.
// Simplified single-widget version of zesis's DesktopConfigOverlay.qml -
// that one drives an arbitrary catalog of widgets (a Repeater over
// DesktopWidgetStore._widgets, snapping to every other widget's edges, plus
// a per-widget background/mask settings card and a widget catalog panel).
// With exactly one widget here, that collapses to: one proxy, snap only to
// screen edges/center, no catalog, no background config.
PanelWindow {
    id: root

    // Must be the same output as DesktopOverlayWindow.qml - the proxy's
    // x/y here are normalized against this window's own width/height, so a
    // mismatched screen (different resolution/aspect ratio) would save a
    // position that looks right here but is wrong once the live overlay
    // (on the actual primary output) picks it back up.
    screen: Quickshell.screens.find(s => s.name === DesktopOverlayStore.primaryOutput) ?? Quickshell.screens[0]

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell:desktop-overlay:edit"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    exclusiveZone: -1
    color: "transparent"
    visible: DesktopOverlayStore.editMode

    property bool snapEnabled: true
    readonly property real snapThreshold: 20

    property bool _selected: false

    // Active alignment guides, set during drag, cleared on release.
    // undefined = hidden, a number = draw guide at that coordinate.
    property var _snapGuideX
    property var _snapGuideY

    // Returns { x, y, guideX, guideY } where guide* may be undefined. Only
    // screen center/edges are candidates - there's no second widget to snap to.
    function _computeSnap(pW, pH, rawX, rawY) {
        var thr = root.snapThreshold;

        var xC = [
            {
                snapX: (root.width - pW) / 2,
                guideX: root.width / 2
            },
            {
                snapX: 0,
                guideX: 0
            },
            {
                snapX: root.width - pW,
                guideX: root.width
            }
        ];
        var yC = [
            {
                snapY: (root.height - pH) / 2,
                guideY: root.height / 2
            },
            {
                snapY: 0,
                guideY: 0
            },
            {
                snapY: root.height - pH,
                guideY: root.height
            }
        ];

        var bX = rawX, bgX = undefined, bdX = thr;
        for (var j = 0; j < xC.length; j++) {
            var dx = Math.abs(rawX - xC[j].snapX);
            if (dx < bdX) {
                bdX = dx;
                bX = xC[j].snapX;
                bgX = xC[j].guideX;
            }
        }

        var bY = rawY, bgY = undefined, bdY = thr;
        for (var k = 0; k < yC.length; k++) {
            var dy = Math.abs(rawY - yC[k].snapY);
            if (dy < bdY) {
                bdY = dy;
                bY = yC[k].snapY;
                bgY = yC[k].guideY;
            }
        }

        return {
            x: bX,
            y: bY,
            guideX: bgX,
            guideY: bgY
        };
    }

    Shortcut {
        sequence: "Escape"
        onActivated: DesktopOverlayStore.setEditMode(false)
    }

    // Background dim
    Rectangle {
        anchors.fill: parent
        color: Theme.withAlpha(Theme.color0, 0.45)
    }

    // The proxy - drag to move, resize handles when selected. Mirrors
    // DesktopOverlayWindow.qml's sizing logic so what you drag here matches
    // what actually renders once you exit edit mode.
    //
    // x/y are permanently declarative (never imperatively assigned during a
    // drag) so they never need the "manually re-attach Qt.binding() after
    // the gesture ends" dance - both drag handlers below just write into the
    // plain state (_nx/_ny, or _resizing + _resizeCenterX/Y) that these
    // bindings already read from.
    Item {
        id: proxy

        property real _nx: DesktopOverlayStore.getPos().nx
        property real _ny: DesktopOverlayStore.getPos().ny

        property bool _resizing: false
        property real _resizeCenterX: 0
        property real _resizeCenterY: 0
        // Raw live value written during a resize drag - kept separate from
        // _previewScale below so that property stays a clean binding
        // (mirrors DesktopOverlayStore.scale normally, this override only
        // while actively resizing) instead of getting permanently detached
        // from the store the first time it's imperatively assigned to.
        property real _liveResizeScale: 1.0
        readonly property real _previewScale: proxy._resizing ? proxy._liveResizeScale : DesktopOverlayStore.scale

        width: proxyContent.item?.implicitWidth ?? 0
        height: proxyContent.item?.implicitHeight ?? 0

        x: proxy._resizing ? (proxy._resizeCenterX - proxy.width / 2) : (proxy._nx * Math.max(1, root.width - proxy.width))
        y: proxy._resizing ? (proxy._resizeCenterY - proxy.height / 2) : (proxy._ny * Math.max(1, root.height - proxy.height))

        Component.onCompleted: {
            var pos = DesktopOverlayStore.getPos();
            proxy._nx = pos.nx;
            proxy._ny = pos.ny;
        }

        // width/height stay bound always - Loader doesn't auto-size to a
        // plain Item's implicitWidth/Height, so read it back explicitly.
        Loader {
            id: proxyContent
            anchors.centerIn: parent
            sourceComponent: ClockWeatherCard {
                contentScale: proxy._previewScale
            }
            width: item?.implicitWidth ?? 0
            height: item?.implicitHeight ?? 0
        }

        DragHandler {
            id: dragger
            target: null
            grabPermissions: PointerHandler.CanTakeOverFromAnything

            property point _startScene: Qt.point(0, 0)
            property point _startPos: Qt.point(0, 0)

            onActiveChanged: {
                if (dragger.active) {
                    dragger._startScene = dragger.centroid.scenePosition;
                    dragger._startPos = Qt.point(proxy.x, proxy.y);
                } else {
                    root._snapGuideX = undefined;
                    root._snapGuideY = undefined;
                    DesktopOverlayStore.setPos(proxy._nx, proxy._ny);
                }
            }

            onCentroidChanged: {
                if (!dragger.active)
                    return;
                var rawX = dragger._startPos.x + (dragger.centroid.scenePosition.x - dragger._startScene.x);
                var rawY = dragger._startPos.y + (dragger.centroid.scenePosition.y - dragger._startScene.y);
                var targetX = rawX, targetY = rawY;
                if (root.snapEnabled) {
                    var s = root._computeSnap(proxy.width, proxy.height, rawX, rawY);
                    targetX = s.x;
                    targetY = s.y;
                    root._snapGuideX = s.guideX;
                    root._snapGuideY = s.guideY;
                } else {
                    root._snapGuideX = undefined;
                    root._snapGuideY = undefined;
                }
                proxy._nx = Math.max(0.0, Math.min(1.0, targetX / Math.max(1, root.width - proxy.width)));
                proxy._ny = Math.max(0.0, Math.min(1.0, targetY / Math.max(1, root.height - proxy.height)));
            }
        }

        TapHandler {
            onTapped: root._selected = !root._selected
        }

        HoverHandler {
            cursorShape: dragger.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: Theme.withAlpha(Theme.accent, root._selected ? 1.0 : (dragger.active ? 1.0 : 0.75))
            border.width: root._selected ? 2 : 1.5
            radius: 8

            Behavior on border.width {
                NumberAnimation {
                    duration: 100
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.bottom
            anchors.topMargin: 4
            text: "Clock & Weather"
            color: root._selected ? Theme.accent : Theme.dimText
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 4
            font.capitalization: Font.AllUppercase
            font.letterSpacing: 1
        }

        // Resize handles: 4 corners + 4 edges, all functionally identical -
        // aspect ratio is locked (see ClockWeatherCard.contentScale), so
        // there's only one degree of freedom (scale) regardless of which
        // handle is grabbed. Dragging any of them scales the whole card
        // uniformly from its own center, by the ratio of the pointer's
        // current distance from center to its distance when the drag started.
        Repeater {
            model: root._selected ? ["nw", "n", "ne", "w", "e", "sw", "s", "se"] : []

            delegate: Rectangle {
                id: handle
                required property string modelData

                readonly property bool _left: modelData.indexOf("w") >= 0
                readonly property bool _right: modelData.indexOf("e") >= 0
                readonly property bool _top: modelData.indexOf("n") >= 0
                readonly property bool _bottom: modelData.indexOf("s") >= 0

                width: 9
                height: width
                radius: width / 2
                color: Theme.color0
                border.color: Theme.accent
                border.width: 1.5
                z: 20

                x: (handle._left ? 0 : handle._right ? proxy.width : proxy.width / 2) - handle.width / 2
                y: (handle._top ? 0 : handle._bottom ? proxy.height : proxy.height / 2) - handle.height / 2

                HoverHandler {
                    cursorShape: {
                        switch (handle.modelData) {
                        case "n":
                        case "s":
                            return Qt.SizeVerCursor;
                        case "e":
                        case "w":
                            return Qt.SizeHorCursor;
                        case "nw":
                        case "se":
                            return Qt.SizeFDiagCursor;
                        default:
                            // ne, sw
                            return Qt.SizeBDiagCursor;
                        }
                    }
                }

                DragHandler {
                    id: resizeDrag
                    target: null
                    grabPermissions: PointerHandler.CanTakeOverFromAnything

                    property real _startScale: 1.0
                    property real _startDist: 1.0

                    onActiveChanged: {
                        if (resizeDrag.active) {
                            proxy._resizeCenterX = proxy.x + proxy.width / 2;
                            proxy._resizeCenterY = proxy.y + proxy.height / 2;
                            resizeDrag._startScale = DesktopOverlayStore.scale;
                            resizeDrag._startDist = Math.max(1, Math.hypot(resizeDrag.centroid.scenePosition.x - proxy._resizeCenterX, resizeDrag.centroid.scenePosition.y - proxy._resizeCenterY));
                            proxy._resizing = true;
                        } else {
                            // Read final geometry while proxy._resizing is
                            // still true - proxy.x/y currently reflect the
                            // center-anchored resize math, so nx/ny come out
                            // consistent with it and there's no jump once
                            // _resizing flips off below and x/y's binding
                            // switches back to the nx/ny-based branch.
                            var rW = Math.max(1, root.width - proxy.width);
                            var rH = Math.max(1, root.height - proxy.height);
                            proxy._nx = Math.max(0.0, Math.min(1.0, proxy.x / rW));
                            proxy._ny = Math.max(0.0, Math.min(1.0, proxy.y / rH));
                            DesktopOverlayStore.setScale(proxy._previewScale);
                            DesktopOverlayStore.setPos(proxy._nx, proxy._ny);
                            proxy._resizing = false;
                        }
                    }

                    onCentroidChanged: {
                        if (!resizeDrag.active)
                            return;
                        var curDist = Math.hypot(resizeDrag.centroid.scenePosition.x - proxy._resizeCenterX, resizeDrag.centroid.scenePosition.y - proxy._resizeCenterY);
                        proxy._liveResizeScale = Math.max(DesktopOverlayStore.minScale, Math.min(DesktopOverlayStore.maxScale, resizeDrag._startScale * (curDist / resizeDrag._startDist)));
                    }
                }
            }
        }
    }

    // Alignment guides (drawn above the proxy)
    Rectangle {
        visible: root._snapGuideX !== undefined
        x: root._snapGuideX !== undefined ? Math.round(root._snapGuideX) : 0
        y: 0
        width: 1
        height: root.height
        color: Theme.accent
        opacity: 0.55
    }

    Rectangle {
        visible: root._snapGuideY !== undefined
        x: 0
        y: root._snapGuideY !== undefined ? Math.round(root._snapGuideY) : 0
        width: root.width
        height: 1
        color: Theme.accent
        opacity: 0.55
    }

    // HUD hint, top centre
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 20
        implicitWidth: modeLabel.implicitWidth + 28
        implicitHeight: modeLabel.implicitHeight + 16
        radius: height / 2
        color: Theme.pillBg

        Text {
            id: modeLabel
            anchors.centerIn: parent
            text: "Drag to move · corners to resize · Esc or Done to exit"
            color: Theme.dimText
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 2
        }
    }

    // Controls, top right
    Row {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 20
        spacing: 8

        Rectangle {
            implicitWidth: snapLabel.implicitWidth + 28
            implicitHeight: snapLabel.implicitHeight + 16
            radius: height / 2
            color: root.snapEnabled ? Theme.withAlpha(Theme.accent, 0.18) : Theme.pillBg
            border.color: root.snapEnabled ? Theme.accent : "transparent"
            border.width: 1

            Text {
                id: snapLabel
                anchors.centerIn: parent
                text: "Snap"
                color: root.snapEnabled ? Theme.accent : Theme.dimText
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 2
            }

            HoverHandler {}
            TapHandler {
                onTapped: root.snapEnabled = !root.snapEnabled
            }
        }

        // Re-resolves location from scratch (IP geolocation, or geocodes the
        // manual city) rather than waiting for the next 30-minute periodic
        // refresh - see WeatherService.refreshLocation()'s comment for why
        // that periodic one deliberately doesn't re-resolve location itself.
        Rectangle {
            implicitWidth: refreshLabel.implicitWidth + 28
            implicitHeight: refreshLabel.implicitHeight + 16
            radius: height / 2
            color: refreshHover.hovered ? Theme.accent : Theme.pillBg
            opacity: WeatherService.loading ? 0.6 : 1.0

            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }

            Text {
                id: refreshLabel
                anchors.centerIn: parent
                text: WeatherService.loading ? "Refreshing…" : "Refresh Location"
                color: refreshHover.hovered ? Theme.onAccentText : Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 2
                font.weight: Font.Medium
            }

            HoverHandler {
                id: refreshHover
            }
            TapHandler {
                enabled: !WeatherService.loading
                onTapped: WeatherService.refreshLocation()
            }
        }

        Rectangle {
            implicitWidth: doneLabel.implicitWidth + 28
            implicitHeight: doneLabel.implicitHeight + 16
            radius: height / 2
            color: doneHover.hovered ? Theme.accent : Theme.pillBg

            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }

            Text {
                id: doneLabel
                anchors.centerIn: parent
                text: "Done"
                color: doneHover.hovered ? Theme.onAccentText : Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 2
                font.weight: Font.Medium
            }

            HoverHandler {
                id: doneHover
            }
            TapHandler {
                onTapped: DesktopOverlayStore.setEditMode(false)
            }
        }
    }
}
