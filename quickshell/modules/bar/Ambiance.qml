import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

Text {
    id: root

    property string track: "/home/elovold/usik/ambiance.mp3"
    property bool playing: false

    readonly property string iconPlay: String.fromCharCode(0xf04b) // fa-play
    readonly property string iconStop: String.fromCharCode(0xf04d) // fa-stop

    text: root.playing ? root.iconStop : root.iconPlay
    color: root.playing ? Theme.activeWorkspace : Theme.text
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize

    Process {
        id: mpv
        command: [ "mpv", "--loop-file=inf", "--no-terminal", root.track ]
        onRunningChanged: root.playing = running
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (mpv.running)
                mpv.signal(15); // SIGTERM
            else
                mpv.running = true;
        }
    }
}
