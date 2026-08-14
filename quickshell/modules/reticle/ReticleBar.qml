import QtQuick

// A single pill-shaped (rounded-cap) reticle line segment, with an optional
// dark outline drawn as a second, larger rounded rect behind it - the same
// "outlined" trick real crosshair overlays (e.g. dilates/crosshair's
// outlined-dot variants) use so a bright reticle color still reads against
// a bright background. Always laid out horizontally (length along width);
// skins rotate the whole Item (default transformOrigin: Center) for
// vertical/diagonal arms rather than this component knowing about angles.
Item {
    id: root

    property real length: 16
    property real thickness: 3
    property color color: "white"
    property color outlineColor: Qt.rgba(0, 0, 0, 0.85)
    property real outlineWidth: 1

    width: length
    height: thickness

    Rectangle {
        anchors.fill: parent
        anchors.margins: -root.outlineWidth
        radius: height / 2
        color: root.outlineColor
        visible: root.outlineWidth > 0
        antialiasing: true
    }
    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.color
        antialiasing: true
    }
}
