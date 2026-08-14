pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.theme

// Small floating toolbar for the drawing overlay: color swatches, pen
// width, and Clear. Right-click-drag anywhere on it to reposition - built
// entirely from PointerHandlers (DragHandler/TapHandler), not MouseArea,
// the same way DesktopEditOverlay.qml's proxy mixes a whole-item DragHandler
// with per-child TapHandlers/DragHandlers without them fighting each other.
// The DragHandler is scoped to the right button only, so left clicks on the
// buttons below reach their own TapHandlers untouched.
Item {
    id: root

    // The window Item to clamp dragging within (DrawWindow.qml passes its
    // own root, which fills the whole screen).
    required property Item boundsItem

    x: 24
    y: 24
    width: implicitWidth
    height: implicitHeight
    implicitWidth: content.implicitWidth + 20
    implicitHeight: content.implicitHeight + 14

    DragHandler {
        acceptedButtons: Qt.RightButton
        target: root
        xAxis.minimum: 0
        xAxis.maximum: Math.max(0, root.boundsItem.width - root.width)
        yAxis.minimum: 0
        yAxis.maximum: Math.max(0, root.boundsItem.height - root.height)
    }

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: Theme.pillBg
        border.color: Theme.pillBorder
        border.width: 1

        // Absorbs left clicks that land on the palette's own padding
        // (rather than a swatch/button below) so they can't fall through
        // to DrawCanvas's full-screen MouseArea and start a stroke under
        // the palette.
        TapHandler {
            acceptedButtons: Qt.LeftButton
        }
    }

    // Shared by both swatch rows below. The selection indicator is a ring
    // drawn AROUND the swatch with a gap (not just a thicker border on the
    // swatch itself), so "selected" reads as a distinct marker rather than
    // a subtle size change.
    Component {
        id: swatchDelegate
        Item {
            id: swatchRoot
            required property string modelData

            readonly property bool selected: DrawStore.penColor === swatchRoot.modelData

            width: 20
            height: 20
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                radius: width / 2
                color: "transparent"
                border.color: Theme.accent
                border.width: 1.5
                visible: swatchRoot.selected
            }

            Rectangle {
                anchors.centerIn: parent
                width: 14
                height: 14
                radius: 7
                color: swatchRoot.modelData
                border.color: Qt.rgba(0, 0, 0, 0.35)
                border.width: 1
            }

            TapHandler {
                acceptedButtons: Qt.LeftButton
                onTapped: DrawStore.setPenColor(swatchRoot.modelData)
            }
        }
    }

    Column {
        id: content
        anchors.centerIn: parent
        spacing: 6

        Row {
            spacing: 8

            Repeater {
                model: DrawStore.colors
                delegate: swatchDelegate
            }

            Rectangle {
                width: 1
                height: 18
                color: Theme.pillBorder
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: widthLabel.implicitWidth + 16
                height: 22
                radius: 11
                color: widthHover.hovered ? Theme.accent : "transparent"
                anchors.verticalCenter: parent.verticalCenter

                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }

                Text {
                    id: widthLabel
                    anchors.centerIn: parent
                    text: DrawStore.penWidth + "px"
                    color: widthHover.hovered ? Theme.onAccentText : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                }

                HoverHandler {
                    id: widthHover
                }
                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onTapped: DrawStore.cyclePenWidth()
                }
            }

            Rectangle {
                width: clearLabel.implicitWidth + 16
                height: 22
                radius: 11
                color: clearHover.hovered ? Theme.accent : "transparent"
                anchors.verticalCenter: parent.verticalCenter

                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }

                Text {
                    id: clearLabel
                    anchors.centerIn: parent
                    text: "Clear"
                    color: clearHover.hovered ? Theme.onAccentText : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                }

                HoverHandler {
                    id: clearHover
                }
                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onTapped: DrawStore.requestClear()
                }
            }
        }

        // Theme row - the shell's own wallust palette (DrawStore.themeColors),
        // for annotating in a color that matches the current theme instead
        // of only the fixed high-contrast row above.
        Row {
            spacing: 8

            Repeater {
                model: DrawStore.themeColors
                delegate: swatchDelegate
            }
        }
    }
}
