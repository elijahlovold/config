pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import "KeybindData.js" as KB

// Physical-keyboard view: color-coded by binding density under the current
// modifier layer / submap filter (set on KeybindsWindow, passed down),
// click a key to inspect all its bindings. Only instantiated while selected
// in KeybindsWindow's view switcher (see the RAM-comparison note there).
Item {
    id: root

    required property var service
    required property var modFilters
    required property string activeSubmap

    // Emitted right after handing a bind off to $EDITOR - KeybindsWindow
    // closes the overlay on this so it doesn't sit on top of the editor.
    signal openedInEditor

    property string selectedKeyId: ""
    // "grid": pressing a mapped key selects that tile (mirrors clicking it).
    // "list": Tab moves here once a key with bindings is selected; ↑/↓ or
    // j/k move the highlight, Enter opens the highlighted bind in $EDITOR.
    property string focusRegion: "grid"
    property int highlightedIndex: -1

    onSelectedKeyIdChanged: {
        root.focusRegion = "grid";
        root.highlightedIndex = -1;
    }

    readonly property int keyUnit: 34
    readonly property int keyGap: 4

    // Modifier filter is per-mod include/exclude (see setModFilter on
    // KeybindsWindow), "contains" rather than exact match: an "include" for
    // Shift shows every bind with Shift (e.g. SUPER+SHIFT+H), not only binds
    // using Shift alone - almost nothing in this config uses a bare
    // modifier with no Super, so exact-match made the filter look broken.
    property var visibleBinds: {
        const filters = root.modFilters;
        const submap = root.activeSubmap;
        return root.service.binds.filter(b => {
            if (b.submap !== submap)
                return false;
            for (const m in filters) {
                if (filters[m] === "include" && !b.mods.includes(m))
                    return false;
                if (filters[m] === "exclude" && b.mods.includes(m))
                    return false;
            }
            return true;
        });
    }

    readonly property int visibleCount: root.visibleBinds.length

    property var bindsBySlot: {
        const map = {};
        for (const b of root.visibleBinds) {
            if (!map[b.slotId])
                map[b.slotId] = [];
            map[b.slotId].push(b);
        }
        return map;
    }

    readonly property var selectedBinds: root.bindsBySlot[root.selectedKeyId] || []

    readonly property int usedKeyCount: KB.COUNTABLE_KEY_IDS.filter(id => (root.bindsBySlot[id] || []).length > 0).length
    readonly property int freeKeyCount: KB.COUNTABLE_KEY_IDS.length - root.usedKeyCount

    // Called from KeybindsWindow's Keys.onPressed with every key that isn't
    // already claimed (Escape). Returns true if it was consumed.
    function handleKeyEvent(event) {
        if (root.focusRegion === "list") {
            if (event.key === Qt.Key_Tab) {
                root.focusRegion = "grid";
                return true;
            }
            if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                root.moveHighlight(-1);
                return true;
            }
            if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                root.moveHighlight(1);
                return true;
            }
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.openHighlighted();
                return true;
            }
            return false;
        }

        if (event.key === Qt.Key_Tab) {
            if (root.selectedKeyId !== "" && root.selectedBinds.length > 0) {
                root.focusRegion = "list";
                root.highlightedIndex = 0;
            }
            return true;
        }

        const keyId = root.keyIdForQtKey(event.key);
        if (keyId) {
            root.selectedKeyId = keyId;
            return true;
        }
        return false;
    }

    function keyIdForQtKey(key) {
        if (key >= Qt.Key_A && key <= Qt.Key_Z)
            return String.fromCharCode(key);
        if (key >= Qt.Key_0 && key <= Qt.Key_9)
            return String.fromCharCode(key);
        switch (key) {
        case Qt.Key_Left:
            return "Left";
        case Qt.Key_Right:
            return "Right";
        case Qt.Key_Up:
            return "Up";
        case Qt.Key_Down:
            return "Down";
        case Qt.Key_Return:
        case Qt.Key_Enter:
            return "Return";
        case Qt.Key_Comma:
            return "comma";
        case Qt.Key_Period:
            return "period";
        case Qt.Key_Slash:
            return "slash";
        case Qt.Key_Semicolon:
            return "semicolon";
        case Qt.Key_Apostrophe:
            return "apostrophe";
        case Qt.Key_QuoteLeft:
            return "grave";
        case Qt.Key_Minus:
            return "minus";
        case Qt.Key_Equal:
            return "equal";
        case Qt.Key_BracketLeft:
            return "bracketleft";
        case Qt.Key_BracketRight:
            return "bracketright";
        case Qt.Key_Backslash:
            return "backslash";
        case Qt.Key_Backspace:
            return "BackSpace";
        case Qt.Key_Print:
            return "Print";
        case Qt.Key_Space:
            return "space";
        default:
            return "";
        }
    }

    function moveHighlight(delta) {
        const n = root.selectedBinds.length;
        if (n === 0)
            return;
        root.highlightedIndex = (root.highlightedIndex + delta + n) % n;
    }

    function openHighlighted() {
        const b = root.selectedBinds[root.highlightedIndex];
        if (b)
            root.openInEditor(b);
    }

    function openInEditor(bind) {
        Editor.openAtLine(KeybindsConfig.sourceFile, root.service.sourceLineFor(bind));
        root.openedInEditor();
    }

    function openFirstEntry(keyId) {
        root.selectedKeyId = keyId;
        const binds = root.bindsBySlot[keyId] || [];
        if (binds.length > 0)
            root.openInEditor(binds[0]);
    }

    Component {
        id: keyComponent
        Item {
            id: cell
            required property var modelData

            readonly property string keyId: cell.modelData.id
            readonly property bool isSpacer: !!cell.modelData.spacer
            readonly property var slotBinds: root.bindsBySlot[cell.keyId] || []
            readonly property int bindCount: cell.slotBinds.length

            width: Math.round(cell.modelData.width * root.keyUnit + (cell.modelData.width - 1) * root.keyGap)
            height: root.keyUnit

            Rectangle {
                visible: !cell.isSpacer
                anchors.fill: parent
                radius: 5
                color: cell.bindCount === 0 ? Theme.hoverBg : cell.bindCount === 1 ? Theme.withAlpha(Theme.accent, 0.35) : Theme.withAlpha(Theme.accent, 0.8)
                border.width: root.selectedKeyId === cell.keyId && cell.keyId !== "" ? 2 : 1
                border.color: root.selectedKeyId === cell.keyId && cell.keyId !== "" ? Theme.accent : Theme.pillBorder

                Text {
                    anchors.centerIn: parent
                    width: parent.width - 4
                    text: cell.modelData.label
                    color: Theme.text
                    font.pixelSize: 10
                    font.family: Theme.fontFamily
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    visible: cell.bindCount >= 2
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 1
                    text: cell.bindCount
                    color: Theme.onAccentText
                    font.pixelSize: 8
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !cell.isSpacer && cell.keyId !== ""
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selectedKeyId = (root.selectedKeyId === cell.keyId ? "" : cell.keyId)
                    onDoubleClicked: root.openFirstEntry(cell.keyId)
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 18

            Column {
                spacing: root.keyGap
                Repeater {
                    model: KB.KEY_ROWS
                    delegate: Row {
                        id: rowDelegate
                        required property var modelData
                        spacing: root.keyGap
                        Repeater {
                            model: rowDelegate.modelData
                            delegate: keyComponent
                        }
                    }
                }
            }

            Column {
                Layout.alignment: Qt.AlignBottom
                spacing: root.keyGap
                Repeater {
                    model: KB.ARROW_CLUSTER
                    delegate: Row {
                        id: arrowRowDelegate
                        required property var modelData
                        spacing: root.keyGap
                        Repeater {
                            model: arrowRowDelegate.modelData
                            delegate: keyComponent
                        }
                    }
                }
            }
        }

        // Media + mouse clusters - not physically part of the TKL block,
        // shown as their own small rows underneath.
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 24

            Row {
                spacing: root.keyGap
                Repeater {
                    model: KB.MEDIA_KEY_IDS
                    delegate: Rectangle {
                        id: mediaChip
                        required property string modelData
                        readonly property var slotBinds: root.bindsBySlot[modelData] || []
                        width: 46
                        height: root.keyUnit
                        radius: 5
                        color: slotBinds.length === 0 ? Theme.hoverBg : Theme.withAlpha(Theme.accent, 0.5)
                        border.width: 1
                        border.color: Theme.pillBorder

                        Text {
                            anchors.centerIn: parent
                            width: parent.width - 4
                            text: KB.MEDIA_KEY_LABELS[mediaChip.modelData]
                            color: Theme.text
                            font.pixelSize: 9
                            font.family: Theme.fontFamily
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedKeyId = (root.selectedKeyId === mediaChip.modelData ? "" : mediaChip.modelData)
                            onDoubleClicked: root.openFirstEntry(mediaChip.modelData)
                        }
                    }
                }
            }

            Row {
                spacing: root.keyGap
                Repeater {
                    model: KB.MOUSE_SLOTS
                    delegate: Rectangle {
                        id: mouseChip
                        required property var modelData
                        readonly property var slotBinds: root.bindsBySlot[modelData.id] || []
                        width: 58
                        height: root.keyUnit
                        radius: 5
                        color: slotBinds.length === 0 ? Theme.hoverBg : Theme.withAlpha(Theme.accent, 0.5)
                        border.width: 1
                        border.color: Theme.pillBorder

                        Text {
                            anchors.centerIn: parent
                            width: parent.width - 4
                            text: mouseChip.modelData.label
                            color: Theme.text
                            font.pixelSize: 9
                            font.family: Theme.fontFamily
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedKeyId = (root.selectedKeyId === mouseChip.modelData.id ? "" : mouseChip.modelData.id)
                            onDoubleClicked: root.openFirstEntry(mouseChip.modelData.id)
                        }
                    }
                }
            }
        }

        // Legend + free-key count
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 16

            Row {
                spacing: 6
                Rectangle {
                    width: 12
                    height: 12
                    radius: 3
                    color: Theme.hoverBg
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "free"
                    color: Theme.dimText
                    font.pixelSize: 11
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Row {
                spacing: 6
                Rectangle {
                    width: 12
                    height: 12
                    radius: 3
                    color: Theme.withAlpha(Theme.accent, 0.35)
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "1 bind"
                    color: Theme.dimText
                    font.pixelSize: 11
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Row {
                spacing: 6
                Rectangle {
                    width: 12
                    height: 12
                    radius: 3
                    color: Theme.withAlpha(Theme.accent, 0.8)
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "2+ binds"
                    color: Theme.dimText
                    font.pixelSize: 11
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Text {
                text: root.freeKeyCount + " / " + KB.COUNTABLE_KEY_IDS.length + " keys free in this layer"
                color: Theme.dimText
                font.pixelSize: 11
            }
        }

        // Inspector
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 90
            radius: 8
            color: Theme.hoverBg
            border.width: 1
            border.color: Theme.pillBorder

            Flickable {
                anchors.fill: parent
                anchors.margins: 10
                contentHeight: inspectorCol.height
                clip: true

                Column {
                    id: inspectorCol
                    width: parent.width
                    spacing: 4

                    Text {
                        visible: root.selectedKeyId === ""
                        text: "Click or press a key to see its bindings."
                        color: Theme.dimText
                        font.pixelSize: 12
                    }

                    Text {
                        visible: root.selectedKeyId !== "" && root.selectedBinds.length === 0
                        text: (KB.KEY_ID_TO_LABEL[root.selectedKeyId] || root.selectedKeyId) + " - no bindings in this layer"
                        color: Theme.dimText
                        font.pixelSize: 12
                    }

                    Text {
                        visible: root.selectedBinds.length > 0
                        text: "Click a bind, or Tab then ↑/↓ (j/k) + Enter, to open it in your editor."
                        color: Theme.dimText
                        font.pixelSize: 10
                    }

                    Repeater {
                        model: root.selectedBinds
                        delegate: Rectangle {
                            id: bindRow
                            required property var modelData
                            required property int index

                            width: inspectorCol.width
                            height: rowLabel.implicitHeight + 4
                            radius: 4
                            color: root.focusRegion === "list" && root.highlightedIndex === bindRow.index ? Theme.withAlpha(Theme.accent, 0.3) : "transparent"

                            Text {
                                id: rowLabel
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: 3
                                text: (bindRow.modelData.mods.length > 0 ? bindRow.modelData.mods.join(" + ") + " + " : "") + (KB.KEY_ID_TO_LABEL[bindRow.modelData.slotId] || bindRow.modelData.key) + "  →  " + KB.labelForBind(bindRow.modelData) + (bindRow.modelData.submap ? "  [" + bindRow.modelData.submap + "]" : "")
                                color: Theme.text
                                font.pixelSize: 12
                                font.family: Theme.fontFamily
                                wrapMode: Text.Wrap
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.openInEditor(bindRow.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
