import QtQuick

// A filled center dot with the same outlined-shape trick as ReticleBar.
Item {
    id: root

    property real diameter: 5
    property color color: "white"
    property color outlineColor: Qt.rgba(0, 0, 0, 0.85)
    property real outlineWidth: 1

    width: diameter
    height: diameter

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
