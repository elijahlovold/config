pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.modules.common

Item {
    id: root

    readonly property MprisPlayer player: {
        const players = Mpris.players.values;
        return players.find(p => p.isPlaying) ?? players[0] ?? null;
    }
    readonly property string title: root.player?.trackTitle ?? ""
    readonly property string artist: root.player?.trackArtist ?? ""
    property bool previewOpen: false
    readonly property string iconPlaying: String.fromCharCode(0xf04b) // fa-play
    readonly property string iconPaused: String.fromCharCode(0xf04c) // fa-pause

    visible: root.player !== null && root.title.length > 0
    implicitWidth: contentRow.width
    implicitHeight: contentRow.height
    width: implicitWidth
    height: implicitHeight

    // Refreshes the position-derived ring below - Mpris doesn't push
    // position updates on its own (same workaround as MusicPreview.qml).
    Timer {
        interval: 1000
        running: root.visible && (root.player?.isPlaying ?? false)
        repeat: true
        onTriggered: {
            root.player.positionChanged();
            ring.requestPaint();
        }
    }

    Row {
        id: contentRow
        spacing: 8

        // Small play/pause glyph ringed by a progress arc.
        Item {
            id: progressIcon
            width: 18
            height: 18
            anchors.verticalCenter: parent.verticalCenter

            readonly property real fraction: (root.player?.length ?? 0) > 0
                ? Math.max(0, Math.min(1, root.player.position / root.player.length)) : 0

            onFractionChanged: ring.requestPaint()

            Canvas {
                id: ring
                anchors.fill: parent
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    const cx = width / 2, cy = height / 2, r = width / 2 - 1.5;
                    ctx.lineWidth = 2;
                    ctx.strokeStyle = Theme.dimText;
                    ctx.beginPath();
                    ctx.arc(cx, cy, r, 0, Math.PI * 2);
                    ctx.stroke();
                    if (progressIcon.fraction > 0) {
                        ctx.strokeStyle = Theme.focusedWorkspace;
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * progressIcon.fraction);
                        ctx.stroke();
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: root.player?.isPlaying ? root.iconPaused : root.iconPlaying
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 5
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 260)
            text: root.artist.length > 0 ? root.title + " - " + root.artist : root.title
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            elide: Text.ElideRight
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.BackButton | Qt.ForwardButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: closeTimer.stop()
        onExited: closeTimer.restart()
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                root.previewOpen = !root.previewOpen;
                return;
            }
            if (!root.player)
                return;
            if (mouse.button === Qt.LeftButton)
                root.player.togglePlaying();
            else if (mouse.button === Qt.BackButton)
                root.player.previous();
            else if (mouse.button === Qt.ForwardButton)
                root.player.next();
        }
    }

    // Grace period so crossing the small gap between the pill and the
    // popup below it (or moving between the two) doesn't cause a flicker
    // close - only actually closes if neither is hovered once it fires.
    Timer {
        id: closeTimer
        interval: 250
        onTriggered: {
            if (!(previewLoader.item?.hovered ?? false))
                root.previewOpen = false;
        }
    }

    Loader {
        id: previewLoader
        active: root.previewOpen && root.player !== null
        sourceComponent: MusicPreview {
            player: root.player
            anchorItem: root
        }
    }

    Connections {
        target: previewLoader.item
        function onHoveredChanged() {
            if (previewLoader.item.hovered)
                closeTimer.stop();
            else
                closeTimer.restart();
        }
    }
}
