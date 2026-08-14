import QtQuick

// Freehand annotation surface: left-drag draws, right-click (on empty
// canvas - DrawPalette.qml intercepts right-clicks on itself for dragging)
// clears. Holding Ctrl while dragging locks the current stroke to a
// straight line from its start point, snapped to the nearest 45° increment
// (0/45/90/135/...) - re-evaluated live on every move for as long as Ctrl
// stays down, so toggling Ctrl mid-drag switches between snapped-line and
// freehand within the same stroke.
//
// Holding Shift instead - checked once, at release, not live like Ctrl -
// takes the loop you just traced and, if it closes back on itself
// reasonably well, replaces it with whichever of a clean rectangle or
// circle it fits more closely (see _snapShape). A rough freehand doodle
// that doesn't close up, or doesn't resemble either template within the
// error threshold, is left exactly as drawn - this only fires on
// deliberate "roughly trace a box/circle" gestures, not general scribbling.
//
// Strokes are kept in a plain JS array and the whole canvas is redrawn on
// every paint (rather than drawing incrementally straight into Canvas's
// persistent backing store) - simplest-correct approach for a short
// annotation session's handful of strokes, not a redraw-cost concern worth
// optimizing away.
Item {
    id: root

    readonly property color outlineColor: Qt.rgba(0, 0, 0, 0.85)
    readonly property real outlineWidth: 1.5

    property var _strokes: []
    property var _current: null
    // Off-screen until the first move, so the indicator doesn't flash at
    // (0,0) before the cursor has actually entered the surface.
    property point _cursorPos: Qt.point(-100, -100)

    function clear() {
        root._strokes = [];
        root._current = null;
        canvas.requestPaint();
    }

    // Returns the point at (x0,y0)-to-(x1,y1)'s distance and angle, with
    // the angle rounded to the nearest 45° step.
    function _snapPoint(x0, y0, x1, y1) {
        var dx = x1 - x0;
        var dy = y1 - y0;
        var step = Math.PI / 4;
        var angle = Math.round(Math.atan2(dy, dx) / step) * step;
        var dist = Math.hypot(dx, dy);
        return {
            x: x0 + dist * Math.cos(angle),
            y: y0 + dist * Math.sin(angle)
        };
    }

    // Returns a clean replacement point list (rectangle or circle outline)
    // if pts looks like a deliberately-traced shape, or null if it should
    // stay freehand (too few points, doesn't close up, or fits neither
    // template well). Fit error is the average distance from each traced
    // point to the candidate shape's boundary, normalized by the shape's
    // own size so it works the same at any stroke scale.
    function _snapShape(pts) {
        if (pts.length < 6)
            return null;

        var minX = pts[0].x, maxX = pts[0].x, minY = pts[0].y, maxY = pts[0].y;
        for (var i = 1; i < pts.length; i++) {
            minX = Math.min(minX, pts[i].x);
            maxX = Math.max(maxX, pts[i].x);
            minY = Math.min(minY, pts[i].y);
            maxY = Math.max(maxY, pts[i].y);
        }
        var w = maxX - minX;
        var h = maxY - minY;
        var diag = Math.hypot(w, h);
        if (diag < 12)
            return null;

        var first = pts[0], last = pts[pts.length - 1];
        var closeGap = Math.hypot(last.x - first.x, last.y - first.y);
        if (closeGap > diag * 0.35)
            return null;

        var cx = (minX + maxX) / 2;
        var cy = (minY + maxY) / 2;
        var radius = (w + h) / 4;

        var rectErrSum = 0, circErrSum = 0;
        for (var j = 0; j < pts.length; j++) {
            var q = pts[j];
            rectErrSum += Math.min(Math.abs(q.x - minX), Math.abs(q.x - maxX), Math.abs(q.y - minY), Math.abs(q.y - maxY));
            circErrSum += Math.abs(Math.hypot(q.x - cx, q.y - cy) - radius);
        }
        var rectErr = (rectErrSum / pts.length) / Math.max(1, (w + h) / 4);
        var circErr = (circErrSum / pts.length) / Math.max(1, radius);

        // Real mouse-drawn circles are rarely round enough to beat the
        // rectangle metric on raw error alone - "distance to nearest of 4
        // edges" is inherently forgiving near corners, so an imperfect
        // circle with any flattened sides tends to score better against
        // the rectangle template than its own wobble deserves. Discounting
        // circErr before comparing fixes that at the ambiguous middle
        // ground without weakening detection of actual rectangles, which
        // score near-zero rectErr regardless (verified numerically: a
        // superellipse rounded-square "circle" attempt misclassified as
        // rect at bias 1.0, correctly flipped to circle at 0.6, while a
        // real traced rectangle's ~0 rectErr never got close to flipping).
        var circleBias = 0.6;
        var biasedCircErr = circErr * circleBias;

        if (Math.min(rectErr, biasedCircErr) > 0.3)
            return null;

        if (rectErr <= biasedCircErr)
            return [
                {
                    x: minX,
                    y: minY
                },
                {
                    x: maxX,
                    y: minY
                },
                {
                    x: maxX,
                    y: maxY
                },
                {
                    x: minX,
                    y: maxY
                },
                {
                    x: minX,
                    y: minY
                }
            ];

        var out = [];
        var segments = 48;
        for (var s = 0; s <= segments; s++) {
            var angle = (s / segments) * Math.PI * 2;
            out.push({
                x: cx + radius * Math.cos(angle),
                y: cy + radius * Math.sin(angle)
            });
        }
        return out;
    }

    Connections {
        target: DrawStore
        function onClearRequested() {
            root.clear();
        }
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        function _path(ctx, pts, color, width) {
            ctx.strokeStyle = color;
            ctx.lineWidth = width;
            ctx.beginPath();
            ctx.moveTo(pts[0].x, pts[0].y);
            for (var j = 1; j < pts.length; j++)
                ctx.lineTo(pts[j].x, pts[j].y);
            ctx.stroke();
        }

        function _dot(ctx, p) {
            var r = DrawStore.penWidth / 2;
            ctx.fillStyle = root.outlineColor;
            ctx.beginPath();
            ctx.arc(p.x, p.y, r + root.outlineWidth, 0, Math.PI * 2);
            ctx.fill();
            ctx.fillStyle = DrawStore.penColor;
            ctx.beginPath();
            ctx.arc(p.x, p.y, r, 0, Math.PI * 2);
            ctx.fill();
        }

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.lineJoin = "round";
            ctx.lineCap = "round";

            for (var i = 0; i < root._strokes.length; i++) {
                var pts = root._strokes[i];
                if (pts.length === 0)
                    continue;
                if (pts.length === 1) {
                    canvas._dot(ctx, pts[0]);
                    continue;
                }
                // Outline pass first (wider, dark) so the colored pass on
                // top reads clearly over any background - same trick as
                // ReticleBar/Dot/Ring's outlined shapes.
                canvas._path(ctx, pts, root.outlineColor, DrawStore.penWidth + root.outlineWidth * 2);
                canvas._path(ctx, pts, DrawStore.penColor, DrawStore.penWidth);
            }
        }
    }

    // Small ring at the cursor showing the current pen color/size, since the
    // system crosshair cursor (below) can't be recolored. Declared after
    // Canvas and MouseArea so it paints on top; being a plain Item with no
    // handlers of its own, it never competes for input.
    Item {
        id: cursorIndicator
        x: root._cursorPos.x - width / 2
        y: root._cursorPos.y - height / 2
        width: Math.max(14, DrawStore.penWidth + 10)
        height: width
        z: 10

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            border.color: root.outlineColor
            border.width: 3
        }
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            border.color: DrawStore.penColor
            border.width: 1.5
        }
        Rectangle {
            anchors.centerIn: parent
            width: 4
            height: 4
            radius: 2
            color: DrawStore.penColor
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.CrossCursor

        onPressed: mouse => {
            if (mouse.button === Qt.RightButton) {
                root.clear();
                return;
            }
            var stroke = [
                {
                    x: mouse.x,
                    y: mouse.y
                }
            ];
            root._strokes.push(stroke);
            root._current = stroke;
            canvas.requestPaint();
        }

        onPositionChanged: mouse => {
            root._cursorPos = Qt.point(mouse.x, mouse.y);
            if (!root._current)
                return;
            if (mouse.modifiers & Qt.ControlModifier) {
                var start = root._current[0];
                var snapped = root._snapPoint(start.x, start.y, mouse.x, mouse.y);
                root._current.splice(1, root._current.length - 1, snapped);
            } else {
                root._current.push({
                    x: mouse.x,
                    y: mouse.y
                });
            }
            canvas.requestPaint();
        }

        onReleased: mouse => {
            if (root._current && (mouse.modifiers & Qt.ShiftModifier)) {
                var snapped = root._snapShape(root._current);
                if (snapped) {
                    root._current.length = 0;
                    for (var k = 0; k < snapped.length; k++)
                        root._current.push(snapped[k]);
                    canvas.requestPaint();
                }
            }
            root._current = null;
        }
    }
}
