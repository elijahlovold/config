pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.common
import qs.modules.theme

// Large desktop clock+date+weather overlay, adapted from zesis's
// DesktopClock.qml (typewriter clock skin) with a compact weather readout
// appended below. timeEngine drives HH:MM; dateEngine drives
// [d1, d2, " ", m1...mN] with day at fixed indices 0-1 and month at 3+, so
// each sub-row renders only its slice - date gets typed when it changes at
// midnight.
//
// zesis's ClockSettings/UIScale/Anim singletons are intentionally not
// ported - this hardcodes their defaults (breathing colon, fixed width,
// 24-hour, no UI-scale multiplier) since nothing here exposes them as user
// settings. The clock face keeps literal white/rgba colors rather than
// Theme.text - that was zesis's own deliberate choice for legibility over
// an arbitrary wallpaper, not an oversight to "fix" by re-theming it.
//
// Inline `component` declarations below (DigitSlot/MonthChar/DayChar) must
// stay direct children of this root Item - QML only allows inline
// components at a document's top level, not nested inside child items.
//
// Typography (font/weight/spacing/tint) varies by ThemeManager.activeTheme -
// see the `_fontFamily`/`_fontWeight`/`_letterSpacing`/`_digitColor`/
// `_faceOpacity` properties below. This is the "token tier" from the
// Structural theming section of CLAUDE.md, not the "skin tier" Workspaces.qml
// uses: the typewriter/layout code is identical across themes, only the
// values fed into the existing Text elements change - no Loader/Component
// duplication needed for a widget whose structure doesn't actually change.
Item {
    id: root

    // Drives every font/pixel size below - resizing this card (see
    // DesktopEditOverlay.qml) means changing this, not stretching a
    // fixed-size layout inside a bigger box. Since every dimension is
    // derived from the same single number, the card's aspect ratio is
    // constant by construction and there's never empty space around the
    // text for it to sit off-center in.
    property real contentScale: 1.0

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight
    width: implicitWidth
    height: implicitHeight

    readonly property real _digitPx: Math.round(80 * root.contentScale)
    readonly property real _dotR: Math.max(1, Math.round(6 * root.contentScale))
    readonly property real _gap: Math.round(4 * root.contentScale)
    readonly property real _divGap: Math.round(14 * root.contentScale)
    readonly property real _dividerW: Math.max(1, Math.round(2 * root.contentScale))
    readonly property real _monthFontPx: Math.max(1, Math.round(12 * root.contentScale))
    readonly property real _dayFontPx: Math.max(1, Math.round(36 * root.contentScale))
    readonly property real _weatherIconPx: Math.max(1, Math.round(26 * root.contentScale))
    readonly property real _weatherTextPx: Math.max(1, Math.round(Theme.fontSize * root.contentScale))
    readonly property real _layoutSpacing: Math.round(10 * root.contentScale)

    // Typography per structural theme (see modules/theme/ThemeManager.qml) -
    // token-tier, not a full skin swap: the typewriter/layout logic above is
    // unchanged, only the face/weight/spacing/tint fed into the existing
    // Text elements varies. "" for font.family is QML's documented default
    // (unset -> falls back to the application font), so Minimal reproduces
    // today's look exactly and doubles as the fallback for any theme without
    // its own case. Deliberately NOT applied to the weather icon glyph below -
    // that Text renders a Font Awesome codepoint (via WeatherService.weatherIcon()),
    // not language text, and neither "serif" nor leaving it unset guarantees
    // the glyph exists in that face - only Theme.fontFamily is known to carry
    // the icon set, so the icon stays pinned to it regardless of theme.
    readonly property string _fontFamily: {
        switch (ThemeManager.activeTheme) {
        case "Cyber":
            return "Rostex";
            // return "Electroharmonix";
        case "Glass":
            return "Death Stinger";
        default:
            return "Nevera";
        }
    }
    // Qt's font matching prefers styleName over weight/italic once it's set
    // (see QFont::setStyleName docs) - Gakuran Demo is a display face that
    // only ships a Regular style, so pin that explicitly rather than asking
    // for Font.Bold and risking a synthesized/faux-bold fallback.
    readonly property string _fontStyleName: ThemeManager.activeTheme === "Cyber" ? "Regular" : ""
    readonly property int _fontWeight: ThemeManager.activeTheme === "Minimal" ? Font.Bold : Font.Light
    readonly property real _letterSpacing: {
        switch (ThemeManager.activeTheme) {
        case "Cyber":
            return 4;
        case "Glass":
            return 1;
        default:
            return 0;
        }
    }
    readonly property color _digitColor: ThemeManager.activeTheme === "Cyber" ? Theme.accent : "white"
    readonly property real _faceOpacity: ThemeManager.activeTheme === "Glass" ? 0.85 : 1.0

    readonly property var _monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

    readonly property real _naturalTimeW: 4 * Math.round(root._digitPx * 0.62) + Math.round(root._dotR * 5) + 4 * root._gap

    // Non-visual state/logic lives directly on root (plain Item, not a
    // positioner) - Column below must contain only the visual rows, or
    // these zero-size logic children would pick up unwanted Column spacing.
    property var _date: new Date()
    property bool _dayChangeInProgress: false
    property real _naturalDateColW: 0

    TypewriterEngine {
        id: timeEngine
    }
    TypewriterEngine {
        id: dateEngine
    }

    Timer {
        running: true
        repeat: true
        interval: 1000
        onTriggered: {
            if (!root._dayChangeInProgress)
                root._naturalDateColW = dateCol.implicitWidth;
            var now = new Date();
            var minuteChanged = now.getMinutes() !== root._date.getMinutes() || now.getHours() !== root._date.getHours();
            var dayChanged = now.getDate() !== root._date.getDate() || now.getMonth() !== root._date.getMonth();
            if (!minuteChanged && !dayChanged) {
                root._date = now;
                return;
            }
            root._date = now;
            if (dayChanged) {
                root._dayChangeInProgress = true;
                dateEngine.animateTo(root._toDateChars(now), true, true);
            } else {
                timeEngine.animateTo(root._toTimeChars(now));
            }
        }
    }

    // Step 1 -> 2: date deleted, now delete time
    // Step 4: date typed last, sequence done
    Connections {
        target: dateEngine
        function onDeletePhaseComplete() {
            if (root._dayChangeInProgress)
                timeEngine.animateTo(root._toTimeChars(root._date), true, true);
        }
        function onTypePhaseComplete() {
            root._dayChangeInProgress = false;
            root._naturalDateColW = dateCol.implicitWidth;
        }
    }

    // Step 2 -> 3: time deleted, now type time first
    // Step 3 -> 4: time typed, now type date
    Connections {
        target: timeEngine
        function onDeletePhaseComplete() {
            if (root._dayChangeInProgress)
                timeEngine.resumeTyping();
        }
        function onTypePhaseComplete() {
            if (root._dayChangeInProgress)
                dateEngine.resumeTyping();
        }
    }

    Component.onCompleted: {
        timeEngine.snapTo(root._toTimeChars(new Date()));
        dateEngine.snapTo(root._toDateChars(new Date()));
    }

    function _toTimeChars(date) {
        var h = date.getHours();
        var m = date.getMinutes();
        return [Math.floor(h / 10).toString(), (h % 10).toString(), ":", Math.floor(m / 10).toString(), (m % 10).toString()];
    }

    function _toDateChars(date) {
        var d = date.getDate();
        var month = root._monthNames[date.getMonth()];
        var arr = [d >= 10 ? Math.floor(d / 10).toString() : " ", (d % 10).toString(), " "];
        for (var i = 0; i < month.length; i++)
            arr.push(month[i]);
        return arr;
    }

    component DigitSlot: Item {
        required property string ch
        readonly property bool _isColon: ch === ":"
        width: _isColon ? Math.round(root._dotR * 5) : Math.round(root._digitPx * 0.62)
        height: root._digitPx

        Text {
            visible: !parent._isColon
            anchors.centerIn: parent
            text: parent.ch
            font.family: root._fontFamily
            font.styleName: root._fontStyleName
            font.pixelSize: root._digitPx
            font.weight: root._fontWeight
            font.letterSpacing: root._letterSpacing
            color: root._digitColor
            opacity: root._faceOpacity
        }

        Column {
            visible: parent._isColon
            anchors.centerIn: parent
            spacing: Math.round(root._dotR * 2)
            opacity: 0.85 * root._faceOpacity

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: root._dotR * 2
                height: root._dotR * 2
                radius: root._dotR
                color: root._digitColor
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: root._dotR * 2
                height: root._dotR * 2
                radius: root._dotR
                color: root._digitColor
            }
        }
    }

    component MonthChar: Item {
        required property string ch
        required property int index
        visible: index >= 3
        implicitWidth: _mT.implicitWidth
        implicitHeight: _mT.implicitHeight

        Text {
            id: _mT
            text: parent.ch
            font.family: root._fontFamily
            font.styleName: root._fontStyleName
            font.pixelSize: root._monthFontPx
            font.weight: root._fontWeight
            font.letterSpacing: 2 + root._letterSpacing
            color: Qt.rgba(1, 1, 1, 0.8)
            opacity: root._faceOpacity
        }
    }

    component DayChar: Item {
        required property string ch
        required property int index
        visible: index < 2
        implicitWidth: _dT.implicitWidth
        implicitHeight: _dT.implicitHeight

        Text {
            id: _dT
            text: parent.ch
            font.family: root._fontFamily
            font.styleName: root._fontStyleName
            font.pixelSize: root._dayFontPx
            font.weight: root._fontWeight
            font.letterSpacing: root._letterSpacing
            color: root._digitColor
            opacity: root._faceOpacity
        }
    }

    Column {
        id: layout
        spacing: root._layoutSpacing

        // Clock + date row

        Item {
            id: clockRow
            width: digitsRow.width + root._divGap + divider.width + root._divGap + Math.max(dateCol.implicitWidth, root._naturalDateColW)
            height: root._digitPx

            Row {
                id: digitsRow
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: root._gap
                width: Math.max(implicitWidth, root._naturalTimeW)

                Repeater {
                    model: timeEngine.model
                    delegate: DigitSlot {}
                }

                Item {
                    visible: timeEngine.cursorVisible
                    width: Math.round(root._digitPx * 0.5)
                    height: root._digitPx
                    Text {
                        anchors.centerIn: parent
                        text: "_"
                        font.family: root._fontFamily
                        font.styleName: root._fontStyleName
                        font.pixelSize: root._digitPx
                        font.weight: root._fontWeight
                        color: timeEngine.cursorOn ? root._digitColor : Qt.rgba(1, 1, 1, 0.12)
                        opacity: timeEngine.cursorOn ? root._faceOpacity : 1.0
                    }
                }
            }

            Rectangle {
                id: divider
                anchors.left: digitsRow.right
                anchors.leftMargin: root._divGap
                anchors.verticalCenter: parent.verticalCenter
                width: root._dividerW
                height: Math.round(root._digitPx * 0.72)
                color: Qt.rgba(1, 1, 1, 0.35)
            }

            Column {
                id: dateCol
                anchors.left: divider.right
                anchors.leftMargin: root._divGap
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                // Month name, dateEngine indices 3+
                Row {
                    spacing: 0
                    Text {
                        width: 0
                        font.pixelSize: root._monthFontPx
                        text: ""
                    }

                    Repeater {
                        model: dateEngine.model
                        delegate: MonthChar {}
                    }

                    Item {
                        visible: dateEngine.cursorVisible && dateEngine.cursor >= 3
                        width: _mCur.implicitWidth
                        height: _mCur.implicitHeight
                        Text {
                            id: _mCur
                            text: "_"
                            font.family: root._fontFamily
                            font.styleName: root._fontStyleName
                            font.pixelSize: root._monthFontPx
                            font.weight: root._fontWeight
                            color: dateEngine.cursorOn ? Qt.rgba(1, 1, 1, 0.8) : Qt.rgba(1, 1, 1, 0.12)
                            opacity: dateEngine.cursorOn ? root._faceOpacity : 1.0
                        }
                    }
                }

                // Day number, dateEngine indices 0-1
                Row {
                    spacing: 0
                    Text {
                        width: 0
                        font.pixelSize: root._dayFontPx
                        text: ""
                    }

                    Repeater {
                        model: dateEngine.model
                        delegate: DayChar {}
                    }

                    Item {
                        visible: dateEngine.cursorVisible && dateEngine.cursor < 3
                        width: _dCur.implicitWidth
                        height: _dCur.implicitHeight
                        Text {
                            id: _dCur
                            text: "_"
                            font.family: root._fontFamily
                            font.styleName: root._fontStyleName
                            font.pixelSize: root._dayFontPx
                            font.weight: root._fontWeight
                            color: dateEngine.cursorOn ? root._digitColor : Qt.rgba(1, 1, 1, 0.12)
                            opacity: dateEngine.cursorOn ? root._faceOpacity : 1.0
                        }
                    }
                }
            }
        }

        // Weather row, compact: icon + temperature + condition. Adapted from
        // zesis's WeatherDisplay.qml, dropped the humidity/wind line and the
        // compact/narrow responsive collapse - this card isn't expected to
        // be squeezed to extreme sizes, and simplicity here is the point.
        Row {
            spacing: root._layoutSpacing
            visible: !WeatherService.loading && WeatherService.error === ""

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: WeatherService.weatherIcon(WeatherService.weatherCode, WeatherService.isDay)
                font.family: Theme.fontFamily
                font.pixelSize: root._weatherIconPx
                color: Theme.text
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: WeatherService.temperature + "°F  " + WeatherService.conditionText(WeatherService.weatherCode)
                font.family: root._fontFamily !== "" ? root._fontFamily : Theme.fontFamily
                font.styleName: root._fontStyleName
                font.pixelSize: root._weatherTextPx
                font.letterSpacing: root._letterSpacing
                color: Theme.dimText
                opacity: root._faceOpacity
            }
        }

        Text {
            visible: WeatherService.loading || WeatherService.error !== ""
            text: WeatherService.loading ? "Loading weather…" : WeatherService.error
            font.family: Theme.fontFamily
            font.pixelSize: root._weatherTextPx
            color: Theme.dimText
        }
    }
}
