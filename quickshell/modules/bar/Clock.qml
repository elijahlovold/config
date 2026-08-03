pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.modules.common

Item {
    id: root

    property bool full: true
    property bool previewOpen: false

    readonly property string clockIcon: String.fromCharCode(0xf017) // fa-clock-o
    readonly property string calendarIcon: String.fromCharCode(0xf073) // fa-calendar

    implicitWidth: contentRow.width
    implicitHeight: contentRow.height
    width: implicitWidth
    height: implicitHeight

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Row {
        id: contentRow
        spacing: 10

        Text {
            text: root.clockIcon + "  " + Qt.formatDateTime(clock.date, root.full ? "hh:mm" : "hh:mm | MM/dd/yy")
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.bold: true
        }

        Text {
            visible: root.full
            text: root.calendarIcon + "  " + Qt.formatDateTime(clock.date, "ddd, MM/dd/yy")
            color: Theme.dimText
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onEntered: closeTimer.stop()
        onExited: closeTimer.restart()
        hoverEnabled: true
        onClicked: root.previewOpen = !root.previewOpen
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
        active: root.previewOpen
        sourceComponent: CalendarPreview {
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
