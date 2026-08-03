pragma ComponentBehavior: Bound
import QtQuick

// Ported from keytree/qml/SearchView.qml. The original read `keyTree.*`
// (search state) and `colorScheme.*` as C++-injected context properties;
// this takes the same search state as explicit properties from
// KeytreeWindow and reads KeytreeColors directly.
Item {
    id: root
    anchors.fill: parent

    property real fontScale: 1.0
    property string searchText: ""
    property var searchResults: []
    property int searchSelection: 0

    readonly property real inputH:  44
    readonly property real resultH: 37

    readonly property color cBg:        KeytreeColors.searchBg
    readonly property color cSelection: KeytreeColors.searchSelection
    readonly property color cText:      KeytreeColors.searchText
    readonly property color cKeyText:   KeytreeColors.keyText

    Rectangle {
        id: panel
        anchors.centerIn: parent
        width:  420
        height: root.inputH + 1 + root.searchResults.length * root.resultH + 24
        radius: 12
        color:        root.cBg
        border.color: KeytreeColors.searchBorder
        border.width: 1

        Column {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 12
            }
            spacing: 0

            // Input row
            Row {
                width: parent.width
                height: root.inputH
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "/"
                    color: root.cKeyText
                    font.pixelSize: Math.round(22 * root.fontScale)
                    font.bold: true
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    clip: true
                    width: parent.width - 32

                    Text {
                        text: root.searchText
                        color: "white"
                        font.pixelSize: Math.round(17 * root.fontScale)
                        font.family: "monospace"
                    }

                    Rectangle {
                        width: 2
                        height: Math.round(19 * root.fontScale)
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.cKeyText

                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { to: 0; duration: 500 }
                            NumberAnimation { to: 1; duration: 100 }
                        }
                    }
                }
            }

            // Divider
            Rectangle {
                width: parent.width
                height: 1
                color:   KeytreeColors.searchBorder
                opacity: 0.5
            }

            // Results
            Repeater {
                model: root.searchResults

                delegate: Rectangle {
                    id: resultDelegate
                    required property string modelData
                    required property int    index

                    width:  panel.width - 24
                    height: root.resultH
                    radius: 5
                    color: resultDelegate.index === root.searchSelection
                        ? root.cSelection
                        : "transparent"

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        text: resultDelegate.modelData
                        color: resultDelegate.index === root.searchSelection ? "white" : root.cText
                        font.pixelSize: Math.round(15 * root.fontScale)
                        font.family: "monospace"
                    }
                }
            }
        }
    }
}
