import QtQuick

// Ported from keytree/qml/RadialView.qml near-verbatim (same ring/spiral
// placement math). Colors read from KeytreeColors directly (already carry
// alpha, Qt #AARRGGBB style). Card/spacing/radius constants below are fixed
// design values multiplied by KeytreeConfig.layout.nodeScale; the popup's
// overall size comes from .ringScale (applied to the window size in
// KeytreeWindow.qml, which r/r1/r2 are fractions of). fontScale only
// touches font.pixelSize lines, driven by KeytreeConfig.layout.fontScale.
Item {
    id: root

    property var    items:            []
    property real   fontScale:        1.0
    property real   nodeScale:        1.0
    property string centerLabel:      ""
    property bool   atRoot:           true
    property string layoutType:       "ring"    // "ring" or "spiral"
    property string nodeShape:        "rect"    // "rect" or "circle"
    property int    ringThreshold:    8         // ring mode: N+ items → two rings
    property int    spiralThreshold:  6         // spiral mode: N+ items → spiral; else single ring
    property int    spiralGapPixels:  8

    readonly property color cLeafBg:    KeytreeColors.leafBg
    readonly property color cGroupBg:   KeytreeColors.groupBg
    readonly property color cKeyText:   KeytreeColors.keyText
    readonly property color cLabelText: KeytreeColors.labelText

    readonly property real cx:      width  / 2
    readonly property real cy:      height / 2
    // Circle mode uses square cards (nodeW=nodeH) so the circular shape matches
    // the bounding box and gap_pixels is geometrically exact.
    readonly property real nodeW:   Math.round((nodeShape === "circle" ? 64 : 76) * nodeScale)
    readonly property real nodeH:   Math.round((nodeShape === "circle" ? 64 : 56) * nodeScale)
    readonly property real centerW: Math.round((nodeShape === "circle" ? 64 : 70) * nodeScale)
    readonly property real centerH: Math.round((nodeShape === "circle" ? 64 : 40) * nodeScale)

    // isSpiral: spiral layout is active only when type=spiral AND count meets threshold.
    // twoRings: two-ring layout is active only when type=ring AND count meets threshold.
    readonly property bool isSpiral:  layoutType === "spiral" && items.length >= spiralThreshold
    readonly property bool twoRings:  layoutType === "ring"   && items.length >= ringThreshold

    // ── Ring layout ───────────────────────────────────────────────────────────
    readonly property int  innerCount:  twoRings ? Math.floor(items.length / 2) : items.length
    readonly property int  outerCount:  twoRings ? (items.length - innerCount) : 0
    readonly property real outerOffset: (twoRings && innerCount % 2 === 0 && outerCount % 2 === 0)
                                            ? Math.PI / outerCount : 0
    readonly property real r:           Math.min(width, height) * 0.40
    readonly property real r1:          Math.min(width, height) * 0.29
    readonly property real r2:          Math.min(width, height) * 0.44
    readonly property real innerR:      twoRings ? r1 : r
    readonly property real outerR:      r2

    // ── Spiral layout ─────────────────────────────────────────────────────────

    // Spiral starts at top (-π/2) and winds outward.
    readonly property real spiralTheta0: -Math.PI / 2
    readonly property real spiralRStart: Math.min(width, height) * 0.13
    // Maximum usable radius: half the window minus half a card width so that
    // cards placed at maxR are fully inside the window on all sides.
    readonly property real spiralREnd:   Math.min(width, height) / 2 - nodeW / 2

    // Growth rate b = P / (2π) where P is the pitch needed to maintain gap_pixels
    // between adjacent arms.
    // Rect: tightest approach at tan(θ)=H/W, min gap = P − √(W²+H²) → P = diag + gap.
    // Circle: tightest approach is purely radial (same angle, adjacent winding),
    //         min gap = P − diameter → P = nodeW + gap.
    readonly property real spiralB: nodeShape === "circle"
        ? (nodeW + spiralGapPixels) / (2 * Math.PI)
        : (Math.sqrt(nodeW * nodeW + nodeH * nodeH) + spiralGapPixels) / (2 * Math.PI)

    // Gap between two same-size axis-aligned rectangles centered at (ax,ay)
    // and (bx,by). Returns 0 when overlapping or touching, positive otherwise.
    function boxGap(ax, ay, bx, by) {
        if (nodeShape === "circle") {
            var cdx = ax - bx, cdy = ay - by
            return Math.sqrt(cdx * cdx + cdy * cdy) - nodeW
        }
        var dx = Math.abs(ax - bx) - nodeW
        var dy = Math.abs(ay - by) - nodeH
        if (dx < 0) dx = 0
        if (dy < 0) dy = 0
        if (dx === 0 && dy === 0) return 0
        if (dx === 0) return dy
        if (dy === 0) return dx
        return Math.sqrt(dx * dx + dy * dy)
    }

    // Placement positions, recomputed whenever layout inputs change.
    // Implements the gap-filling Archimedean spiral walk from the Opus analysis:
    //   - arc-length step ds = max(1, gap/4) keeps overshoot ≤ gap/4
    //   - adaptive dθ = ds / sqrt(r² + b²) converts to angle increment
    //   - stop at first θ where min bounding-box gap to all placed items ≥ gap_pixels
    readonly property var spiralPositions: {
        var n = items.length
        if (!isSpiral || n === 0 || width < 10 || height < 10) return []

        var _cx     = cx
        var _cy     = cy
        var _W      = nodeW
        var _H      = nodeH
        var gap     = spiralGapPixels
        var theta0  = spiralTheta0
        var rStart  = spiralRStart
        var maxR    = spiralREnd
        var b       = spiralB
        var ds      = Math.max(1.0, gap / 4)

        var result = []
        result.push({ x: _cx + rStart * Math.cos(theta0),
                      y: _cy + rStart * Math.sin(theta0),
                      theta: theta0 })

        var theta = theta0
        for (var i = 1; i < n; i++) {
            var placed = false
            while (true) {
                var r = rStart + b * (theta - theta0)
                if (r > maxR) {
                    // Ran out of room: clamp and accept sub-gap spacing
                    result.push({ x: _cx + maxR * Math.cos(theta),
                                  y: _cy + maxR * Math.sin(theta),
                                  theta: theta })
                    placed = true
                    break
                }
                theta += ds / Math.sqrt(r * r + b * b)
                var x = _cx + r * Math.cos(theta)
                var y = _cy + r * Math.sin(theta)

                // Min gap to all already-placed items
                var g = Infinity
                var isCircle = nodeShape === "circle"
                for (var j = 0; j < result.length; j++) {
                    var p  = result[j]
                    var gj
                    if (isCircle) {
                        var cdx = x - p.x, cdy = y - p.y
                        gj = Math.sqrt(cdx * cdx + cdy * cdy) - _W
                    } else {
                        var dx = Math.abs(x - p.x) - _W
                        var dy = Math.abs(y - p.y) - _H
                        if (dx < 0) dx = 0
                        if (dy < 0) dy = 0
                        gj = (dx === 0 && dy === 0) ? 0
                           : (dx === 0) ? dy
                           : (dy === 0) ? dx
                           : Math.sqrt(dx * dx + dy * dy)
                    }
                    if (gj < g) {
                        g = gj
                        if (g < gap) break  // early-out: already too close
                    }
                }
                if (g >= gap) {
                    result.push({ x: x, y: y, theta: theta })
                    placed = true
                    break
                }
            }
        }
        return result
    }

    // ── Connectors / spiral curve ─────────────────────────────────────────────

    Canvas {
        anchors.fill: parent

        property var  watchItems:           root.items
        property bool watchIsSpiral:        root.isSpiral
        property bool watchTwoRings:        root.twoRings
        property var  watchSpiralPositions: root.spiralPositions
        onWatchItemsChanged:           requestPaint()
        onWatchIsSpiralChanged:        requestPaint()
        onWatchTwoRingsChanged:        requestPaint()
        onWatchSpiralPositionsChanged: requestPaint()
        onWidthChanged:                requestPaint()
        onHeightChanged:               requestPaint()

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            var n = root.items.length
            if (n < 2) return

            ctx.strokeStyle = KeytreeColors.connector
            ctx.lineWidth   = 1
            ctx.lineCap     = "round"

            if (root.isSpiral) {
                var positions = root.spiralPositions
                if (positions.length < 2) return

                // Smooth Archimedean spiral from first to last placed position
                var b       = root.spiralB
                var theta0  = root.spiralTheta0
                var rStart  = root.spiralRStart
                var tStart  = positions[0].theta
                var tEnd    = positions[positions.length - 1].theta
                var STEPS   = 160

                ctx.globalAlpha = 0.35
                ctx.beginPath()
                for (var s = 0; s <= STEPS; s++) {
                    var t  = tStart + (tEnd - tStart) * s / STEPS
                    var rr = rStart + b * (t - theta0)
                    var px = root.cx + rr * Math.cos(t)
                    var py = root.cy + rr * Math.sin(t)
                    if (s === 0) ctx.moveTo(px, py)
                    else         ctx.lineTo(px, py)
                }
                ctx.stroke()
            } else {
                // Ring mode: spokes from center to each node
                ctx.globalAlpha = 0.45
                var two        = root.twoRings
                var innerCount = root.innerCount
                var outerCount = root.outerCount
                var innerR     = root.innerR
                var outerR     = root.outerR
                var outerOff   = root.outerOffset

                for (var i = 0; i < n; i++) {
                    var onInner   = !two || i < innerCount
                    var ringIdx   = onInner ? i : (i - innerCount)
                    var ringCount = onInner ? (two ? innerCount : n) : outerCount
                    var ringR     = onInner ? innerR : outerR
                    var offset    = onInner ? 0 : outerOff
                    var angle     = ringCount === 1
                        ? -Math.PI / 2
                        : -Math.PI / 2 + (ringIdx / ringCount) * 2 * Math.PI + offset

                    ctx.beginPath()
                    ctx.moveTo(root.cx, root.cy)
                    ctx.lineTo(root.cx + ringR * Math.cos(angle),
                               root.cy + ringR * Math.sin(angle))
                    ctx.stroke()
                }
            }
        }
    }

    // ── Center element ────────────────────────────────────────────────────────

    Item {
        x: root.cx - width  / 2
        y: root.cy - height / 2
        width:  atRoot ? 10 : root.centerW
        height: atRoot ? 10 : root.centerH

        Rectangle {
            visible: atRoot
            anchors.fill: parent
            radius: width / 2
            color:   KeytreeColors.centerDot
            opacity: 0.85
        }

        Rectangle {
            visible: !atRoot
            anchors.fill: parent
            radius:       root.nodeShape === "circle"
                ? Math.min(width, height) / 2
                : Math.round(8 * root.nodeScale)
            color:        root.cGroupBg
            border.color: KeytreeColors.centerDot
            border.width: 1

            Text {
                anchors.centerIn: parent
                text:  centerLabel
                color: root.cLabelText
                font.pixelSize: Math.round(14 * fontScale)
                font.bold: true
                width: parent.width - 8
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }
    }

    // ── Node cards ────────────────────────────────────────────────────────────

    Repeater {
        model: root.items

        delegate: Item {
            id: node

            required property var modelData
            required property int index

            // Ring position
            readonly property bool onInner:   !root.twoRings || index < root.innerCount
            readonly property int  ringIdx:   onInner ? index : (index - root.innerCount)
            readonly property int  ringCount: onInner
                                                ? (root.twoRings ? root.innerCount : root.items.length)
                                                : root.outerCount
            readonly property real ringR:     onInner ? root.innerR : root.outerR
            readonly property real ringOff:   onInner ? 0 : root.outerOffset
            readonly property real ringAngle: ringCount === 1
                ? -Math.PI / 2
                : -Math.PI / 2 + (ringIdx / ringCount) * 2 * Math.PI + ringOff

            // Active position: spiral positions array in spiral mode, ring calc otherwise
            readonly property real px: (root.isSpiral && index < root.spiralPositions.length)
                ? root.spiralPositions[index].x
                : root.cx + ringR * Math.cos(ringAngle)
            readonly property real py: (root.isSpiral && index < root.spiralPositions.length)
                ? root.spiralPositions[index].y
                : root.cy + ringR * Math.sin(ringAngle)

            x: px - root.nodeW / 2
            y: py - root.nodeH / 2
            width:  root.nodeW
            height: root.nodeH

            Rectangle {
                anchors.fill: parent
                radius:       root.nodeShape === "circle"
                    ? Math.min(width, height) / 2
                    : Math.round((modelData.isLeaf ? 12 : 5) * root.nodeScale)
                color:        modelData.isLeaf ? root.cLeafBg    : root.cGroupBg
                border.color: modelData.isLeaf ? KeytreeColors.leafBorder : KeytreeColors.groupBorder
                border.width: modelData.isLeaf ? 2 : 1
            }

            Column {
                anchors.centerIn: parent
                spacing: 3

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 3

                    Text {
                        visible: modelData.icon.length > 0
                        text: modelData.icon
                        color: root.cKeyText
                        font.pixelSize: Math.round(20 * fontScale)
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: modelData.key
                        color: root.cKeyText
                        font.pixelSize: Math.round(25 * fontScale)
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData.label
                    color: root.cLabelText
                    font.pixelSize: Math.round(13 * fontScale)
                    width: Math.round(88 * root.nodeScale)
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
            }
        }
    }
}
