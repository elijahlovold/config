pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

// Persisted position/scale/style/color + show/hide state for the aiming
// reticle overlay. Mirrors modules/desktop/DesktopOverlayStore.qml's
// position/scale persistence and edit-mode plumbing - see
// ReticleEditOverlay.qml for the reused drag/resize interaction.
Singleton {
    id: root

    readonly property var styles: ["Cross", "Dot", "Circle", "Chevron", "Brackets"]
    // High-contrast colors independent of the wallust palette - the
    // reticle needs to stay visible over arbitrary game content, not match
    // the shell's theme.
    readonly property var colors: ["#39ff14", "#ff2d2d", "#00e5ff", "#ff00ff", "#ffffff"]

    readonly property real minScale: 0.4
    readonly property real maxScale: 4.0

    property bool visible: data.visible
    // Edit mode is a transient UI state, not persisted - always starts closed.
    property bool editMode: false
    property real scale: data.scale
    property string style: data.style
    property string color: data.color
    // Whether every shape gets a dark contrast stroke - see ReticleView.qml's
    // outlineWidth binding. Persisted since it's a real visibility choice,
    // not a transient edit-mode preview toggle like Snap.
    property bool outlined: data.outlined

    readonly property string _configDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/quickshell-reticle"
    readonly property string _path: _configDir + "/position.json"

    function setVisible(v) {
        data.visible = v;
        _save();
    }

    function toggleVisible() {
        setVisible(!root.visible);
    }

    function setEditMode(v) {
        root.editMode = v;
        if (v)
            setVisible(true);
    }

    function toggleEditMode() {
        setEditMode(!root.editMode);
    }

    function getPos() {
        return {
            nx: data.nx,
            ny: data.ny
        };
    }

    function setPos(nx, ny) {
        data.nx = Math.max(0.0, Math.min(1.0, nx));
        data.ny = Math.max(0.0, Math.min(1.0, ny));
        _save();
    }

    function setScale(s) {
        data.scale = Math.max(root.minScale, Math.min(root.maxScale, s));
        _save();
    }

    function setStyle(s) {
        data.style = s;
        _save();
    }

    function cycleStyle() {
        var idx = root.styles.indexOf(root.style);
        setStyle(root.styles[(idx + 1) % root.styles.length]);
    }

    function setColor(c) {
        data.color = c;
        _save();
    }

    function cycleColor() {
        var idx = root.colors.indexOf(root.color);
        setColor(root.colors[(idx + 1) % root.colors.length]);
    }

    function setOutlined(v) {
        data.outlined = v;
        _save();
    }

    function toggleOutlined() {
        setOutlined(!root.outlined);
    }

    function _save() {
        posFile.setText(JSON.stringify({
            visible: data.visible,
            nx: data.nx,
            ny: data.ny,
            scale: data.scale,
            style: data.style,
            color: data.color,
            outlined: data.outlined
        }));
    }

    function _load(text) {
        if (!text)
            return;
        try {
            var obj = JSON.parse(text) || {};
            data.visible = obj.visible ?? false;
            data.nx = obj.nx ?? 0.5;
            data.ny = obj.ny ?? 0.5;
            data.scale = obj.scale ?? 1.0;
            data.style = obj.style ?? "Cross";
            data.color = obj.color ?? "#39ff14";
            data.outlined = obj.outlined ?? true;
        } catch (_) {}
    }

    QtObject {
        id: data
        property bool visible: false
        property real nx: 0.5
        property real ny: 0.5
        property real scale: 1.0
        property string style: "Cross"
        property string color: "#39ff14"
        property bool outlined: true
    }

    // FileView.setText() doesn't create missing parent directories, so make
    // sure the cache dir exists before the first _save() can ever run.
    Process {
        command: ["mkdir", "-p", root._configDir]
        running: true
    }

    FileView {
        id: posFile
        path: root._path
        blockLoading: true
        printErrors: false
        onLoaded: root._load(posFile.text())
    }

    Component.onCompleted: {
        root._load(posFile.text());
    }
}
