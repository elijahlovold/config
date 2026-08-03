pragma ComponentBehavior: Bound
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.modules.common

// Grid-tile wallpaper picker, replacing an nsxiv-based flow. Directory
// listing via FolderListModel (native, no subprocess). Thumbnails are
// generated once via vipsthumbnail into a persistent disk cache keyed by
// filename (single flat directory, so basenames are already unique) and
// reused on every subsequent open - only new/changed files regenerate.
// Same overlay-layer-surface trick as KeytreeWindow.qml for centering.
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
    WlrLayershell.namespace: "quickshell:imagepicker"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    mask: Region {
        item: contentItem
    }

    // ── Window geometry ────────────────────────────────────────────────────────
    // The window is sized to a whole number of tile columns/rows rather than
    // an arbitrary screen fraction, so the grid fills exactly to its last
    // full tile with no leftover partial-cell gap on the right or bottom.
    // ~72%/78% of the screen is the target size; columns/rows round to
    // whatever whole tile count lands closest to that, then the window
    // shrinks to exactly fit them (clamped so it can never exceed the
    // actual screen even if rounding would overshoot).
    readonly property int cellW: ImagePickerConfig.tileSize + 10
    readonly property int cellH: ImagePickerConfig.tileSize + 10
    readonly property int panelMargin: 18
    readonly property int chrome: panelMargin * 2

    readonly property int columns: Math.max(1, Math.min(Math.round((root.screen.width * 0.72 - chrome) / cellW), Math.floor((root.screen.width - chrome) / cellW)))
    readonly property int rows: Math.max(1, Math.min(Math.round((root.screen.height * 0.78 - chrome) / cellH), Math.floor((root.screen.height - chrome) / cellH)))

    // ── Directory listing ─────────────────────────────────────────────────────
    FolderListModel {
        id: folderModel
        folder: Qt.resolvedUrl("file://" + ImagePickerConfig.directory)
        nameFilters: [...ImagePickerConfig.imageExtensions, ...ImagePickerConfig.videoExtensions].map(ext => "*." + ext)
        sortField: FolderListModel.Name
        sortReversed: false
        showDirs: false
        showFiles: true
        caseSensitive: false
        onCountChanged: root.rebuildImages()
    }

    property var images: []
    property int currentIndex: 0

    function rebuildImages() {
        const list = [];
        for (let i = 0; i < folderModel.count; i++) {
            const path = folderModel.get(i, "filePath");
            if (!path)
                continue;
            list.push({
                path: path,
                thumbPath: "",
                ready: false
            });
        }
        root.images = list;
        root.currentIndex = 0;
        root.startThumbnailGeneration();
    }

    // ── Thumbnail generation (vipsthumbnail for images, ffmpeg frame-grab
    // for videos, both batched, both disk-cached) ─────────────────────────────
    property bool generating: false

    // First loop marks already-cached files ready immediately (fast path -
    // just filesystem stat calls, no image/video processing) so a warm
    // cache shows the whole grid almost instantly; only truly new/changed
    // files get regenerated, split by extension into images (batched
    // through vipsthumbnail, chunks of 24 - it takes many inputs per call)
    // and videos (ffmpeg only takes one input per call, so those run in a
    // per-file loop instead - still fine since video wallpapers are
    // typically a much smaller set than image ones).
    readonly property string genScript: [
        'set -uo pipefail',
        'shopt -s nocasematch',
        'cachedir="$1"; shift',
        'size="$1"; shift',
        'videoext="$1"; shift',
        'mkdir -p "$cachedir"',
        'chunk=24',
        'video_re="\\.(${videoext})$"',
        'image_stale=()',
        'video_stale=()',
        'for f in "$@"; do',
        '    b="$(basename "$f")"',
        '    thumb="$cachedir/${b%.*}.png"',
        '    if [ ! -f "$thumb" ] || [ "$f" -nt "$thumb" ]; then',
        '        if [[ "$f" =~ $video_re ]]; then',
        '            video_stale+=("$f")',
        '        else',
        '            image_stale+=("$f")',
        '        fi',
        '    else',
        '        echo "FILE $f"',
        '    fi',
        'done',
        'n=${#image_stale[@]}',
        'i=0',
        'while [ "$i" -lt "$n" ]; do',
        '    batch=("${image_stale[@]:$i:$chunk}")',
        '    vipsthumbnail "${batch[@]}" -s "$size" --path="$cachedir/%s.png" 2>/dev/null',
        '    for f in "${batch[@]}"; do',
        '        echo "FILE $f"',
        '    done',
        '    i=$((i + chunk))',
        'done',
        'for f in "${video_stale[@]}"; do',
        '    b="$(basename "$f")"',
        '    thumb="$cachedir/${b%.*}.png"',
        '    ffmpeg -y -ss 1 -i "$f" -vframes 1 -vf "scale=${size}:-1" "$thumb" >/dev/null 2>&1',
        '    echo "FILE $f"',
        'done',
        'echo "GENDONE"'
    ].join("\n")

    function startThumbnailGeneration() {
        if (root.images.length === 0)
            return;
        genProc.command = ["bash", "-c", root.genScript, "imagepicker-thumbgen",
            ImagePickerConfig.cacheDir, String(ImagePickerConfig.thumbnailSize),
            ImagePickerConfig.videoExtensions.join("|"),
            ...root.images.map(img => img.path)];
        root.generating = true;
        genProc.running = true;
    }

    function markReady(path) {
        const b = path.split("/").pop();
        const dot = b.lastIndexOf(".");
        const noExt = dot > 0 ? b.slice(0, dot) : b;
        const thumbPath = ImagePickerConfig.cacheDir + "/" + noExt + ".png";
        root.images = root.images.map(img => img.path === path ? {
            path: img.path,
            thumbPath: thumbPath,
            ready: true
        } : img);
    }

    Process {
        id: genProc
        stdout: SplitParser {
            onRead: data => {
                const line = data.trim();
                if (line === "GENDONE") {
                    root.generating = false;
                    return;
                }
                const m = line.match(/^FILE (.+)$/);
                if (m)
                    root.markReady(m[1]);
            }
        }
    }

    // ── Selection ──────────────────────────────────────────────────────────────
    function selectIndex(i) {
        if (i < 0 || i >= root.images.length)
            return;
        Quickshell.execDetached([ImagePickerConfig.applyCommand, "--select", root.images[i].path]);
        root.dismissed();
    }

    // ── Overlay chrome (mirrors KeytreeWindow.qml) ────────────────────────────
    Component.onCompleted: {
        Quickshell.execDetached(["hyprctl", "dispatch", "movecursor",
            String(Math.round(root.screen.x + root.screen.width / 2)),
            String(Math.round(root.screen.y + root.screen.height / 2))]);
        contentItem.forceActiveFocus();
    }

    Item {
        id: contentItem
        anchors.centerIn: parent
        width: root.columns * root.cellW + root.chrome
        height: root.rows * root.cellH + root.chrome
        focus: true

        onActiveFocusChanged: {
            if (!activeFocus)
                root.dismissed();
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape || event.key === Qt.Key_Q) {
                root.dismissed();
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.selectIndex(root.currentIndex);
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
                root.currentIndex = Math.max(0, root.currentIndex - 1);
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
                root.currentIndex = Math.min(root.images.length - 1, root.currentIndex + 1);
            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                root.currentIndex = Math.max(0, root.currentIndex - root.columns);
            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                root.currentIndex = Math.min(root.images.length - 1, root.currentIndex + root.columns);
            } else {
                return;
            }
            event.accepted = true;
        }

        Rectangle {
            id: panel
            anchors.fill: parent
            radius: 16
            color: "#CC0D0D12"
            border.color: "#33FFFFFF"
            border.width: 1

            Item {
                anchors.fill: parent
                anchors.margins: root.panelMargin

                GridView {
                    id: grid
                    anchors.fill: parent
                    cellWidth: root.cellW
                    cellHeight: root.cellH
                    cacheBuffer: ImagePickerConfig.tileSize * 4
                    clip: true
                    model: root.images
                    currentIndex: root.currentIndex

                    delegate: Item {
                        id: tile
                        required property var modelData
                        required property int index
                        width: grid.cellWidth
                        height: grid.cellHeight

                        Rectangle {
                            id: card
                            anchors.fill: parent
                            anchors.margins: 5
                            radius: 8
                            color: "#1AFFFFFF"
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: tile.modelData.ready ? Qt.resolvedUrl(tile.modelData.thumbPath) : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                            }

                            // Selection frame: black ring against the image itself
                            // (works regardless of the image's own colors) plus a
                            // brighter outer ring against the dark panel behind it.
                            // Overlaid rather than baked into `card`'s own border so
                            // the image's layout never shifts on selection change.
                            Rectangle {
                                visible: tile.index === root.currentIndex
                                anchors.fill: parent
                                radius: parent.radius
                                color: "transparent"
                                border.width: 3
                                border.color: "black"
                            }
                            Rectangle {
                                visible: tile.index === root.currentIndex
                                anchors.fill: parent
                                anchors.margins: 3
                                radius: Math.max(0, parent.radius - 3)
                                color: "transparent"
                                border.width: 2
                                border.color: Theme.focusedWorkspace
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.currentIndex = tile.index;
                                root.selectIndex(tile.index);
                            }
                        }
                    }
                }
            }
        }
    }
}
