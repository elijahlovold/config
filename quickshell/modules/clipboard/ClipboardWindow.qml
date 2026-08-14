pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.modules.theme

// Search-as-you-type replacement for `cliphist list | wofi --dmenu | cliphist
// decode | wl-copy`, with visual thumbnails for image entries. Same overlay-
// layer-surface trick as KeytreeWindow.qml/ImagePickerWindow.qml for
// centering + OnDemand keyboard focus, and the same fake-TextInput search
// technique as KeytreeWindow.qml (event.text appended to a plain string,
// not a real TextInput - keeps the single Keys.onPressed on `contentItem`
// as the one place that owns all keyboard behavior, independent of skin).
//
// Structural theming: all state (cliphist list, thumbnails, filter,
// selection) lives here on the root window, exactly like Workspaces.qml.
// `skinLoader` below switches purely the *rendering* by ThemeManager.
// activeTheme; each skin is a self-contained inline Component reading this
// file's `root` id directly. New skins don't touch any of the logic above.
PanelWindow {
    id: root

    signal dismissed

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.namespace: "quickshell:clipboard"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    mask: Region {
        item: contentItem
    }

    readonly property int panelWidth: Math.min(560, Math.round(root.screen.width * 0.42))
    readonly property int panelHeight: Math.min(480, Math.round(root.screen.height * 0.55))

    // ── Clipboard list ─────────────────────────────────────────────────────
    property var entries: []
    property string filterText: ""
    property int selectedIndex: 0

    readonly property var filteredEntries: {
        const q = root.filterText.toLowerCase();
        if (q.length === 0)
            return root.entries;
        return root.entries.filter(e => e.preview.toLowerCase().includes(q));
    }

    function refresh() {
        listProc.running = true;
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            id: listCollector
            onStreamFinished: {
                const lines = listCollector.text.split("\n").filter(l => l.length > 0);
                root.entries = lines.map(line => {
                    const tab = line.indexOf("\t");
                    const id = tab >= 0 ? line.slice(0, tab) : line;
                    const preview = tab >= 0 ? line.slice(tab + 1) : line;
                    return {
                        id: id,
                        raw: line, // cliphist decode wants the whole "<id>\t<preview>" line on stdin, not just the id
                        preview: preview,
                        isImage: preview.indexOf("binary data") !== -1,
                        thumbPath: "",
                        ready: false
                    };
                });
                root.selectedIndex = 0;
                root.startThumbnailGeneration();
            }
        }
    }

    // ── Image thumbnails ───────────────────────────────────────────────────
    // Same disk-cached FILE/GENDONE protocol as ImagePickerWindow.qml's
    // genScript, just decoding via cliphist instead of reading a file path -
    // cache key is cliphist's own row id, which is stable until that entry
    // ages out of history.
    readonly property string genScript: [
        'set -uo pipefail',
        'cachedir="$1"; shift',
        'size="$1"; shift',
        'mkdir -p "$cachedir"',
        'while [ "$#" -gt 0 ]; do',
        '    id="$1"; line="$2"; shift 2',
        '    thumb="$cachedir/$id.png"',
        '    if [ ! -f "$thumb" ]; then',
        '        tmp="$(mktemp)"',
        '        printf "%s" "$line" | cliphist decode > "$tmp" 2>/dev/null',
        '        vipsthumbnail "$tmp" -s "$size" -o "$cachedir/$id.png" 2>/dev/null',
        '        rm -f "$tmp"',
        '    fi',
        '    echo "FILE $id"',
        'done',
        'echo "GENDONE"'
    ].join("\n")

    function startThumbnailGeneration() {
        const images = root.entries.filter(e => e.isImage);
        if (images.length === 0)
            return;
        const args = ["bash", "-c", root.genScript, "clipboard-thumbgen", ClipboardConfig.cacheDir, String(ClipboardConfig.thumbnailSize)];
        for (const e of images)
            args.push(e.id, e.raw);
        genProc.command = args;
        genProc.running = true;
    }

    function markReady(id) {
        const thumbPath = ClipboardConfig.cacheDir + "/" + id + ".png";
        root.entries = root.entries.map(e => e.id === id ? {
            id: e.id,
            raw: e.raw,
            preview: e.preview,
            isImage: e.isImage,
            thumbPath: thumbPath,
            ready: true
        } : e);
    }

    Process {
        id: genProc
        stdout: SplitParser {
            onRead: data => {
                const m = data.trim().match(/^FILE (.+)$/);
                if (m)
                    root.markReady(m[1]);
            }
        }
    }

    // ── Selection / deletion ───────────────────────────────────────────────
    function selectIndex(i) {
        const list = root.filteredEntries;
        if (i < 0 || i >= list.length)
            return;
        Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | cliphist decode | wl-copy', "sh", list[i].raw]);
        root.dismissed();
    }

    function deleteIndex(i) {
        const list = root.filteredEntries;
        if (i < 0 || i >= list.length)
            return;
        Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | cliphist delete', "sh", list[i].raw]);
        deleteRefreshTimer.restart();
    }

    Timer {
        id: deleteRefreshTimer
        interval: 150
        onTriggered: root.refresh()
    }

    // Cursor starts wherever it was when mod+V was pressed, which is
    // usually off the panel (contentItem is only ever screen-centered, not
    // full-screen). With focus-follows-mouse, moving the mouse from there
    // crosses back onto whatever's under the clickthrough mask and steals
    // keyboard focus, instantly triggering the activeFocus-loss dismiss
    // below - same fix ImagePickerWindow.qml uses for the same reason.
    Component.onCompleted: {
        root.refresh();
        Quickshell.execDetached(["hyprctl", "dispatch", "movecursor",
            String(Math.round(root.screen.x + root.screen.width / 2)),
            String(Math.round(root.screen.y + root.screen.height / 2))]);
        contentItem.forceActiveFocus();
    }

    Item {
        id: contentItem
        anchors.centerIn: parent
        width: root.panelWidth
        height: root.panelHeight
        focus: true

        onActiveFocusChanged: {
            if (!activeFocus)
                root.dismissed();
        }

        // Single place owning all keyboard behavior, regardless of active
        // skin - Up/Down navigate, Enter selects+copies+closes, Delete
        // removes the entry from cliphist, Escape closes, Backspace/typed
        // characters edit the (fake, KeytreeWindow.qml-style) search field.
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.dismissed();
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.selectIndex(root.selectedIndex);
            } else if (event.key === Qt.Key_Delete) {
                root.deleteIndex(root.selectedIndex);
            } else if (event.key === Qt.Key_Up || (event.key === Qt.Key_P && (event.modifiers & Qt.ControlModifier))) {
                root.selectedIndex = Math.max(0, root.selectedIndex - 1);
            } else if (event.key === Qt.Key_Down || (event.key === Qt.Key_N && (event.modifiers & Qt.ControlModifier))) {
                root.selectedIndex = Math.min(root.filteredEntries.length - 1, root.selectedIndex + 1);
            } else if (event.key === Qt.Key_Backspace) {
                root.filterText = root.filterText.slice(0, -1);
                root.selectedIndex = 0;
            } else if (event.key === Qt.Key_U && (event.modifiers & Qt.ControlModifier)) {
                root.filterText = "";
                root.selectedIndex = 0;
            } else if (event.text.length > 0 && !(event.modifiers & Qt.ControlModifier)) {
                root.filterText += event.text;
                root.selectedIndex = 0;
            } else {
                return;
            }
            event.accepted = true;
        }

        Loader {
            id: skinLoader
            anchors.fill: parent
            sourceComponent: {
                switch (ThemeManager.activeTheme) {
                case "Cyber":
                    return cyberSkin;
                case "Glass":
                    return glassSkin;
                default:
                    return minimalSkin;
                }
            }
        }
    }

    // ── Minimal (default/fallback) ─────────────────────────────────────────
    Component {
        id: minimalSkin

        Rectangle {
            radius: 12
            color: Theme.pillBg
            border.color: Theme.pillBorder
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                Rectangle {
                    width: parent.width
                    height: 32
                    radius: 6
                    color: Theme.hoverBg
                    border.color: Theme.pillBorder
                    border.width: 1

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: (root.filterText.length > 0 ? root.filterText : "Search clipboard…") + "▏"
                        color: root.filterText.length > 0 ? Theme.text : Theme.dimText
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }
                }

                ListView {
                    id: listView
                    width: parent.width
                    height: parent.height - 42
                    clip: true
                    model: root.filteredEntries
                    currentIndex: root.selectedIndex
                    highlightMoveDuration: 80

                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        required property int index
                        width: listView.width
                        height: 44
                        radius: 6
                        color: row.index === root.selectedIndex ? Theme.hoverBg : "transparent"

                        Row {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 8

                            Rectangle {
                                width: 32
                                height: 32
                                radius: 4
                                color: Theme.hoverBg
                                visible: row.modelData.isImage
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    source: row.modelData.ready ? Qt.resolvedUrl(row.modelData.thumbPath) : ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: false
                                }
                            }

                            Text {
                                width: parent.width - (row.modelData.isImage ? 40 : 0)
                                anchors.verticalCenter: parent.verticalCenter
                                text: row.modelData.isImage ? "[image]" : row.modelData.preview
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 2
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.selectedIndex = row.index
                            onClicked: root.selectIndex(row.index)
                        }
                    }
                }
            }
        }
    }

    // ── Cyber ───────────────────────────────────────────────────────────────
    // Sharp corners, monospace-prompt search row, bordered (not filled)
    // selection - reads as a terminal-ish command palette.
    Component {
        id: cyberSkin

        Rectangle {
            radius: 0
            color: Theme.pillBg
            border.color: Theme.accent
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Row {
                    width: parent.width
                    spacing: 6

                    Text {
                        text: ">"
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.bold: true
                    }
                    Text {
                        width: parent.width - 16
                        text: (root.filterText.length > 0 ? root.filterText : "search") + "_"
                        color: root.filterText.length > 0 ? Theme.text : Theme.dimText
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.pillBorder
                }

                ListView {
                    id: cyberList
                    width: parent.width
                    height: parent.height - 30
                    clip: true
                    model: root.filteredEntries
                    currentIndex: root.selectedIndex
                    highlightMoveDuration: 60

                    delegate: Rectangle {
                        id: cyberRow
                        required property var modelData
                        required property int index
                        width: cyberList.width
                        height: 40
                        radius: 0
                        color: "transparent"
                        border.width: cyberRow.index === root.selectedIndex ? 1 : 0
                        border.color: Theme.accent

                        Row {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 8

                            Rectangle {
                                width: 28
                                height: 28
                                radius: 0
                                color: Theme.hoverBg
                                visible: cyberRow.modelData.isImage
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    source: cyberRow.modelData.ready ? Qt.resolvedUrl(cyberRow.modelData.thumbPath) : ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: false
                                }
                            }

                            Text {
                                width: parent.width - (cyberRow.modelData.isImage ? 36 : 0)
                                anchors.verticalCenter: parent.verticalCenter
                                text: cyberRow.modelData.isImage ? "[image]" : cyberRow.modelData.preview
                                color: cyberRow.index === root.selectedIndex ? Theme.accent : Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 2
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.selectedIndex = cyberRow.index
                            onClicked: root.selectIndex(cyberRow.index)
                        }
                    }
                }
            }
        }
    }

    // ── Glass ───────────────────────────────────────────────────────────────
    // Translucent rounded panel; a single ListView `highlight` delegate
    // slides between rows instead of each row carrying its own selection
    // fill - same "one shared indicator" trick as Workspaces.qml's Glass
    // skin, just using ListView's built-in highlight instead of hand-rolled
    // x/width Behaviors since a vertical list is ListView's native case.
    Component {
        id: glassSkin

        Rectangle {
            radius: 18
            color: Theme.withAlpha(Theme.pillBg, 0.6)
            border.width: 1
            border.color: Theme.withAlpha(Theme.foreground, 0.15)

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                Rectangle {
                    width: parent.width
                    height: 34
                    radius: height / 2
                    color: Theme.withAlpha(Theme.foreground, 0.08)
                    border.width: 1
                    border.color: Theme.withAlpha(Theme.foreground, 0.15)

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.filterText.length > 0 ? root.filterText : "Search clipboard…"
                        color: root.filterText.length > 0 ? Theme.text : Theme.dimText
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }
                }

                ListView {
                    id: glassList
                    width: parent.width
                    height: parent.height - 44
                    clip: true
                    model: root.filteredEntries
                    currentIndex: root.selectedIndex
                    highlightMoveDuration: 220
                    highlightMoveVelocity: -1
                    highlight: Rectangle {
                        radius: 10
                        color: Theme.withAlpha(Theme.focusedWorkspace, 0.25)
                        border.width: 1
                        border.color: Theme.withAlpha(Theme.focusedWorkspace, 0.6)
                    }

                    delegate: Item {
                        id: glassRow
                        required property var modelData
                        required property int index
                        width: glassList.width
                        height: 44

                        Row {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            Rectangle {
                                width: 30
                                height: 30
                                radius: 8
                                color: Theme.withAlpha(Theme.foreground, 0.08)
                                visible: glassRow.modelData.isImage
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    source: glassRow.modelData.ready ? Qt.resolvedUrl(glassRow.modelData.thumbPath) : ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: false
                                }
                            }

                            Text {
                                width: parent.width - (glassRow.modelData.isImage ? 38 : 0)
                                anchors.verticalCenter: parent.verticalCenter
                                text: glassRow.modelData.isImage ? "[image]" : glassRow.modelData.preview
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 2
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.selectedIndex = glassRow.index
                            onClicked: root.selectIndex(glassRow.index)
                        }
                    }
                }
            }
        }
    }
}
