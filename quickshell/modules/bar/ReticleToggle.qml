import QtQuick
import qs.modules.theme
import qs.modules.reticle

// Left-click toggles the aiming reticle overlay on/off. Right-click enters
// edit mode (drag/resize/style/color) - see modules/reticle/ReticleEditOverlay.qml.
// Mirrors DesktopWidgetToggle.qml's interaction shape exactly.
Text {
    id: root

    // Codepoint is above 0xffff (Nerd Font Supplementary PUA-A), unlike the
    // Font Awesome 4 icons elsewhere in the bar which all fit in 16 bits -
    // fromCharCode would silently truncate it, so fromCodePoint is required
    // here specifically.
    readonly property string icon: String.fromCodePoint(0xf013b)

    text: root.icon
    color: ReticleStore.editMode ? Theme.accent : (ReticleStore.visible ? Theme.text : Theme.dimText)
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton)
                ReticleStore.toggleVisible();
            else if (mouse.button === Qt.RightButton)
                ReticleStore.toggleEditMode();
        }
    }
}
