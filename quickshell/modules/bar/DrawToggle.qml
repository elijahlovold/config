import QtQuick
import qs.modules.theme
import qs.modules.draw

// Left-click toggles the freehand drawing overlay on/off (which also
// discards whatever was drawn - see DrawStore.qml). Right-click clears the
// canvas without closing it, the closest thing Draw has to Reticle/Desktop's
// right-click-for-edit-mode secondary action. Mirrors ReticleToggle.qml's
// interaction shape.
Text {
    id: root

    // Codepoint is above 0xffff (Nerd Font Supplementary PUA-A), same as
    // ReticleToggle's icon - fromCharCode would silently truncate it.
    readonly property string icon: String.fromCodePoint(0xf0f49)

    text: root.icon
    color: DrawStore.visible ? Theme.accent : Theme.dimText
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton)
                DrawStore.toggleVisible();
            else if (mouse.button === Qt.RightButton)
                DrawStore.requestClear();
        }
    }
}
