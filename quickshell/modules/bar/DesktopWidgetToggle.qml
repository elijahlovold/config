import QtQuick
import qs.modules.common
import qs.modules.desktop

// Left-click toggles the desktop clock+weather overlay on/off. Right-click
// enters edit mode (drag/resize) - see modules/desktop/DesktopEditOverlay.qml.
Text {
    id: root

    readonly property string icon: String.fromCharCode(0xf108) // fa-desktop

    text: root.icon
    color: DesktopOverlayStore.editMode ? Theme.accent : (DesktopOverlayStore.visible ? Theme.text : Theme.dimText)
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton)
                DesktopOverlayStore.toggleVisible();
            else if (mouse.button === Qt.RightButton)
                DesktopOverlayStore.toggleEditMode();
        }
    }
}
