import QtQuick

// A stroked (unfilled) circle, outlined the same way as ReticleBar/ReticleDot -
// a larger dark ring behind with a thicker stroke, so its extra width peeks
// out past the colored ring on both the inner and outer edge.
Item {
    id: root

    property real diameter: 24
    property real ringWidth: 2
    property color color: "white"
    property color outlineColor: Qt.rgba(0, 0, 0, 0.85)
    property real outlineWidth: 1

    width: diameter
    height: diameter

    Rectangle {
        anchors.fill: parent
        anchors.margins: -root.outlineWidth
        radius: width / 2
        color: "transparent"
        border.color: root.outlineColor
        border.width: root.ringWidth + root.outlineWidth * 2
        visible: root.outlineWidth > 0
        antialiasing: true
    }
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.color: root.color
        border.width: root.ringWidth
        antialiasing: true
    }
}
