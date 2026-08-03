pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.modules.common

// Month-grid popup, right-click-toggled open from Clock.qml. Same pipeline
// as MusicPreview.qml: the calendar grid itself is pure QML/JS (Date math),
// no script needed - only clicking a day to open/create its Obsidian daily
// note shells out, since that's a real filesystem+URI-scheme action.
// (ported/adapted from ilyamiro-quickshell's CalendarPopup.qml, which also
// bundled a weather widget and class-schedule panel - dropped here, out of
// scope for "calendar popup" and not requested.)
PopupWindow {
    id: popup

    required property Item anchorItem

    readonly property alias hovered: cardHoverHandler.hovered

    readonly property string dailyNoteScript: "todays-notes"

    readonly property var todayDate: new Date()
    property int monthOffset: 0
    readonly property var displayDate: new Date(popup.todayDate.getFullYear(), popup.todayDate.getMonth() + popup.monthOffset, 1)
    readonly property string iconPrev: String.fromCharCode(0xf104) // fa-angle-left
    readonly property string iconNext: String.fromCharCode(0xf105) // fa-angle-right
    readonly property string iconToday: String.fromCharCode(0xf073) // fa-calendar

    ListModel { id: dayModel }

    function rebuildGrid() {
        dayModel.clear();
        const year = popup.displayDate.getFullYear();
        const month = popup.displayDate.getMonth();
        const todayY = popup.todayDate.getFullYear();
        const todayM = popup.todayDate.getMonth();
        const todayD = popup.todayDate.getDate();

        let firstDow = new Date(year, month, 1).getDay(); // 0 = Sunday
        firstDow = firstDow === 0 ? 6 : firstDow - 1; // convert to Monday-first index

        const daysInMonth = new Date(year, month + 1, 0).getDate();
        const daysInPrevMonth = new Date(year, month, 0).getDate();
        const prevMonth = month === 0 ? 11 : month - 1;
        const prevYear = month === 0 ? year - 1 : year;
        const nextMonth = month === 11 ? 0 : month + 1;
        const nextYear = month === 11 ? year + 1 : year;

        for (let i = firstDow - 1; i >= 0; i--) {
            dayModel.append({ day: daysInPrevMonth - i, month: prevMonth, year: prevYear, inMonth: false, isToday: false });
        }
        for (let d = 1; d <= daysInMonth; d++) {
            dayModel.append({ day: d, month: month, year: year, inMonth: true, isToday: year === todayY && month === todayM && d === todayD });
        }
        const remaining = 42 - dayModel.count;
        for (let d = 1; d <= remaining; d++) {
            dayModel.append({ day: d, month: nextMonth, year: nextYear, inMonth: false, isToday: false });
        }
    }

    function openDailyNote(year, month, day) {
        const date = String(year) + "-"
            + String(month + 1).padStart(2, "0") + "-"
            + String(day).padStart(2, "0");
        Quickshell.execDetached([
            "alacritty", "-e", "sh", "-c", 'nvim "$(todays-notes "$1")"', "sh", date
        ]);
    }

    onDisplayDateChanged: rebuildGrid()
    Component.onCompleted: rebuildGrid()

    anchor {
        item: popup.anchorItem
        edges: Edges.Bottom
        gravity: Edges.Bottom
        margins.top: 0
    }

    visible: true
    implicitWidth: 280
    implicitHeight: card.height
    color: "transparent"

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
                height: 24

                Text {
                    id: prevBtn
                    width: 24
                    height: 24
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: popup.iconPrev
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.monthOffset -= 1
                    }
                }
                Item {
                    id: monthLabelWrap
                    width: parent.width - prevBtn.width - nextBtn.width - todayBtn.width
                    height: 24

                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: Qt.formatDateTime(popup.displayDate, "MMMM")
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.bold: true

                            MouseArea {
                                anchors.fill: parent
                                onWheel: wheel => popup.monthOffset += wheel.angleDelta.y > 0 ? 1 : -1
                            }
                        }
                        Text {
                            text: Qt.formatDateTime(popup.displayDate, "yyyy")
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.bold: true

                            MouseArea {
                                anchors.fill: parent
                                onWheel: wheel => popup.monthOffset += (wheel.angleDelta.y > 0 ? 1 : -1) * 12
                            }
                        }
                    }
                }
                Text {
                    id: todayBtn
                    width: 24
                    height: 24
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: popup.iconToday
                    color: popup.monthOffset === 0 ? Theme.accent : Theme.dimText
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.monthOffset = 0
                    }
                }
                Text {
                    id: nextBtn
                    width: 24
                    height: 24
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: popup.iconNext
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.monthOffset += 1
                    }
                }
            }

            Row {
                width: parent.width

                Repeater {
                    model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                    delegate: Text {
                        required property string modelData
                        width: layout.width / 7
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        color: Theme.dimText
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 3
                        font.bold: true
                    }
                }
            }

            Grid {
                width: parent.width
                columns: 7

                Repeater {
                    model: dayModel
                    delegate: Rectangle {
                        id: dayCell
                        required property int day
                        required property int month
                        required property int year
                        required property bool inMonth
                        required property bool isToday

                        width: layout.width / 7
                        height: width
                        radius: 6
                        color: dayCell.isToday ? Theme.accent
                             : dayMa.containsMouse ? Theme.pillBorder
                             : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: dayCell.day
                            color: dayCell.isToday ? Theme.onAccentText
                                 : dayCell.inMonth ? Theme.text
                                 : Theme.dimText
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 2
                        }

                        MouseArea {
                            id: dayMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: popup.openDailyNote(dayCell.year, dayCell.month, dayCell.day)
                        }
                    }
                }
            }
        }
    }
}
