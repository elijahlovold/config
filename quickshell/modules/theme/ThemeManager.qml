pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

// Structural/artistic theme selection - independent of modules/common
// Theme.qml's wallust palette. Theme.qml answers "what colors" (regenerated
// from the wallpaper); this answers "what shapes/motion" (hand-authored,
// user-selected). A widget that wants to look meaningfully different per
// theme reads ThemeManager.activeTheme and Loaders between its own inline
// Component blocks - see modules/bar/Workspaces.qml for the reference
// pattern. Widgets that don't care just keep using Theme.* tokens and never
// reference this singleton at all.
Singleton {
    id: root

    // Single source of truth for which theme names exist. Adding a theme
    // here doesn't require every widget to implement it - widgets that
    // don't recognize the active theme name fall back to their own default
    // skin (see the switch-with-default pattern in Workspaces.qml).
    readonly property var themes: ["Minimal", "Cyber", "Glass"]
    property string activeTheme: data.activeTheme

    function setTheme(name) {
        if (root.themes.indexOf(name) === -1)
            return;
        data.activeTheme = name;
        root._save();
    }

    function next() {
        const i = root.themes.indexOf(root.activeTheme);
        root.setTheme(root.themes[(i + 1) % root.themes.length]);
    }

    readonly property string _configDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/quickshell"
    readonly property string _path: root._configDir + "/theme.json"

    function _save() {
        themeFile.setText(JSON.stringify({
            activeTheme: data.activeTheme
        }));
    }

    function _load(text) {
        if (!text)
            return;
        try {
            const obj = JSON.parse(text) || {};
            if (obj.activeTheme && root.themes.indexOf(obj.activeTheme) !== -1)
                data.activeTheme = obj.activeTheme;
        } catch (_) {}
    }

    QtObject {
        id: data
        property string activeTheme: "Minimal"
    }

    // FileView.setText() doesn't create missing parent directories, so make
    // sure the cache dir exists before the first _save() can ever run.
    Process {
        command: ["mkdir", "-p", root._configDir]
        running: true
    }

    FileView {
        id: themeFile
        path: root._path
        blockLoading: true
        printErrors: false
        onLoaded: root._load(themeFile.text())
    }

    Component.onCompleted: {
        root._load(themeFile.text());
    }
}
