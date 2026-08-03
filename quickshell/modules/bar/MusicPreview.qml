pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import qs.modules.common

// Expanded "now playing" card, right-click-toggled open from Music.qml.
// Circular art with a glow ring while playing, marquee title, and device
// routing - all sourced natively from Mpris/Pipewire, no external scripts
// (ported/adapted from ilyamiro-quickshell's MusicPopup.qml, which relied
// on playerctl/wpctl/imagemagick polling scripts for the same data we
// already have as live QML properties).
PopupWindow {
    id: popup

    required property MprisPlayer player
    required property Item anchorItem

    // Exposed so Music.qml can keep this open while the cursor is over the
    // card itself, not just the pill that spawned it.
    readonly property alias hovered: cardHoverHandler.hovered

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property string deviceIcon: {
        const name = popup.sink?.name ?? "";
        return name.includes("bluez") ? String.fromCharCode(0xf293) // fa-bluetooth
                                       : String.fromCharCode(0xf028); // fa-volume-up
    }
    readonly property string deviceName: {
        const name = popup.sink?.name ?? "";
        const desc = popup.sink?.description ?? "";
        let label;
        if (name.includes("bluez"))
            label = desc.length > 0 ? desc : "Bluetooth";
        else if (name.includes("usb"))
            label = "USB Audio";
        else
            label = desc.length > 0 ? desc : "Speaker";
        return label.length > 20 ? label.slice(0, 20) + "…" : label;
    }

    PwObjectTracker {
        objects: [popup.sink]
    }

    // Not every player reports a usable rate range (many just report
    // 1.0-1.0, meaning "not supported" per the MPRIS convention).
    readonly property bool rateSupported: (popup.player?.minRate ?? 1) < (popup.player?.maxRate ?? 1)
    readonly property string speedIcon: String.fromCharCode(0xf0e4) // fa-tachometer
    readonly property var rateSteps: [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]

    function cycleRate() {
        if (!popup.player)
            return;
        const steps = popup.rateSteps.filter(r => r >= popup.player.minRate - 0.001 && r <= popup.player.maxRate + 0.001);
        if (steps.length === 0)
            return;
        const idx = steps.findIndex(r => Math.abs(r - popup.player.rate) < 0.01);
        popup.player.rate = steps[(idx + 1) % steps.length];
    }

    // Centered under the pill, flush against its bottom edge (no gap) so
    // the card reads as an extension of the pill rather than a separate
    // floating tooltip - reinforced below by matching the pill's radius
    // and colors.
    anchor {
        item: popup.anchorItem
        edges: Edges.Bottom
        gravity: Edges.Bottom
        margins.top: 0
    }

    visible: true
    implicitWidth: 380
    implicitHeight: card.height
    color: "transparent"

    // Keeps position/length-derived bindings (the progress bar) live -
    // Mpris doesn't push position updates on its own.
    Timer {
        interval: 1000
        running: popup.player?.isPlaying ?? false
        repeat: true
        onTriggered: popup.player.positionChanged()
    }

    Rectangle {
        id: card
        width: popup.implicitWidth
        height: layout.implicitHeight + 32
        radius: 8
        color: Theme.pillBg
        border.color: Theme.pillBorder
        border.width: 1

        HoverHandler {
            id: cardHoverHandler
        }

        Column {
            id: layout
            anchors.centerIn: parent
            width: parent.width - 32
            spacing: 12

            Row {
                width: parent.width
                spacing: 14

                ClippingRectangle {
                    id: artWrap
                    width: 92
                    height: 92
                    radius: width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.pillBg
                    border.width: 2
                    border.color: (popup.player?.isPlaying ?? false) ? Theme.focusedWorkspace : Theme.pillBorder
                    Behavior on border.color { ColorAnimation { duration: 400 } }

                    Image {
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        source: popup.player?.trackArtUrl ?? ""
                    }
                }

                Column {
                    width: parent.width - artWrap.width - 14
                    anchors.verticalCenter: artWrap.verticalCenter
                    spacing: 5

                    // Marquee title - only scrolls if it doesn't fit.
                    Item {
                        id: titleClip
                        width: parent.width
                        height: titleMain.implicitHeight
                        clip: true

                        readonly property int gap: 40
                        readonly property bool overflow: titleMain.implicitWidth > titleClip.width

                        Row {
                            id: titleRow
                            spacing: titleClip.gap

                            Text {
                                id: titleMain
                                text: popup.player?.trackTitle ?? ""
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize + 2
                                font.bold: true

                                onTextChanged: {
                                    titleRow.x = 0;
                                    titleAnim.restart();
                                }
                            }
                            Text {
                                text: titleMain.text
                                visible: titleClip.overflow
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize + 2
                                font.bold: true
                            }
                        }

                        SequentialAnimation {
                            id: titleAnim
                            loops: Animation.Infinite
                            running: titleClip.overflow

                            PauseAnimation { duration: 2000 }
                            NumberAnimation {
                                target: titleRow
                                property: "x"
                                from: 0
                                to: -(titleMain.implicitWidth + titleClip.gap)
                                duration: (titleMain.implicitWidth + titleClip.gap) * 20
                            }
                            PropertyAction { target: titleRow; property: "x"; value: 0 }
                        }
                    }

                    Text {
                        width: parent.width
                        text: popup.player?.trackArtist ?? ""
                        color: Theme.dimText
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        elide: Text.ElideRight
                    }

                    Row {
                        spacing: 6
                        Text {
                            text: popup.deviceIcon
                            color: Theme.dimText
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 2
                        }
                        Text {
                            text: popup.deviceName
                            color: Theme.dimText
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 2
                        }
                        Text {
                            visible: popup.rateSupported
                            text: popup.speedIcon + " " + (popup.player?.rate ?? 1).toFixed(2) + "x"
                            color: speedMa.containsMouse ? Theme.text : Theme.dimText
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 2
                            MouseArea {
                                id: speedMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: popup.cycleRate()
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: progressTrack
                width: parent.width
                height: 5
                radius: 2.5
                color: Theme.dimText

                readonly property real fraction: (popup.player?.length ?? 0) > 0
                    ? (popup.player.position / popup.player.length) : 0

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, progressTrack.fraction))
                    height: parent.height
                    radius: parent.radius
                    color: Theme.focusedWorkspace
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: popup.player?.canSeek ?? false
                    onClicked: mouse => {
                        popup.player.position = (mouse.x / width) * popup.player.length;
                    }
                }
            }

            Item {
                width: parent.width
                height: positionLabel.implicitHeight

                Text {
                    id: positionLabel
                    anchors.left: parent.left
                    text: {
                        const s = Math.floor(popup.player?.position ?? 0);
                        return "%1:%2".arg(Math.floor(s / 60)).arg(String(s % 60).padStart(2, "0"));
                    }
                    color: Theme.dimText
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 1
                }
                Text {
                    anchors.right: parent.right
                    text: {
                        const s = Math.floor(popup.player?.length ?? 0);
                        return "%1:%2".arg(Math.floor(s / 60)).arg(String(s % 60).padStart(2, "0"));
                    }
                    color: Theme.dimText
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 1
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 30

                readonly property string iconPrev: String.fromCharCode(0xf048) // fa-step-backward
                readonly property string iconPlay: String.fromCharCode(0xf04b) // fa-play
                readonly property string iconPause: String.fromCharCode(0xf04c) // fa-pause
                readonly property string iconNext: String.fromCharCode(0xf051) // fa-step-forward

                Text {
                    text: parent.iconPrev
                    color: (popup.player?.canGoPrevious ?? false) ? Theme.text : Theme.dimText
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 5
                    MouseArea {
                        anchors.fill: parent
                        enabled: popup.player?.canGoPrevious ?? false
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.player.previous()
                    }
                }
                Text {
                    text: popup.player?.isPlaying ? parent.iconPause : parent.iconPlay
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 5
                    MouseArea {
                        anchors.fill: parent
                        enabled: popup.player?.canTogglePlaying ?? false
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.player.togglePlaying()
                    }
                }
                Text {
                    text: parent.iconNext
                    color: (popup.player?.canGoNext ?? false) ? Theme.text : Theme.dimText
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 5
                    MouseArea {
                        anchors.fill: parent
                        enabled: popup.player?.canGoNext ?? false
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.player.next()
                    }
                }
            }
        }
    }
}
