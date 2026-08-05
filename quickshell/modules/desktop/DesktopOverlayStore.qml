pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

// Persisted position/scale + show/hide state for the single desktop
// clock+weather overlay. Simplified single-widget version of zesis's
// DesktopWidgetStore.qml - that one manages an arbitrary catalog of desktop
// widgets (globe, sysmon, per-widget backgrounds/masks, ...), none of which
// apply here since there's exactly one overlay.
//
// There's no independent width/height override - only a single uniform
// `scale` factor. The card's own font sizes derive from it (see
// ClockWeatherCard.qml's contentScale), so resizing is genuinely "make the
// text bigger/smaller" rather than cropping/padding a fixed-size card
// inside an arbitrary box, and its aspect ratio never changes.
Singleton {
    id: root

    readonly property real minScale: 0.4
    readonly property real maxScale: 3.0

    // Output name (matches Hyprland's monitor block / ShellScreen.name),
    // pinning both DesktopOverlayWindow.qml and DesktopEditOverlay.qml to
    // the primary monitor - mirrors Bar.qml's own convention of hardcoding
    // output names for per-monitor behavior. Without this, PanelWindow falls
    // back to whichever screen currently has focus/cursor, which is why the
    // overlay used to jump monitors on reload.
    readonly property string primaryOutput: "DP-2"

    property bool visible: data.visible
    // Edit mode is a transient UI state, not persisted - always starts closed.
    property bool editMode: false
    property real scale: data.scale

    readonly property string _configDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/quickshell-desktop"
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

    function getScale() {
        return data.scale;
    }

    function setScale(s) {
        data.scale = Math.max(root.minScale, Math.min(root.maxScale, s));
        _save();
    }

    function _save() {
        posFile.setText(JSON.stringify({
            visible: data.visible,
            nx: data.nx,
            ny: data.ny,
            scale: data.scale
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
        } catch (_) {}
    }

    QtObject {
        id: data
        property bool visible: false
        property real nx: 0.5
        property real ny: 0.5
        property real scale: 1.0
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
