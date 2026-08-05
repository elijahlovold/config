import QtQuick
import Quickshell.Io
import "KeybindData.js" as KB

// Live introspection into Hyprland's actually-loaded binds, via
// `hyprctl binds -j` - ground truth after keybinds.lua has run (loops like
// the workspace 1-10 binding already expanded into individual entries), not
// a re-parse of the Lua source. Only ever instantiated while the Keybinds
// overlay is open (see Keybinds.qml's Loader) - no background polling.
//
// Also loads keybinds.lua's raw text (separately from hyprctl) purely to
// resolve a bind back to its source line for "open in editor" - see
// KeybindData.js's findSourceLine for the heuristic and its limits.
QtObject {
    id: root

    property var binds: []
    property var submapNames: []
    property string sourceText: ""

    function refresh() {
        proc._buf = "";
        proc.running = true;
    }

    function sourceLineFor(bind) {
        return root.sourceText ? KB.findSourceLine(root.sourceText, bind) : null;
    }

    Component.onCompleted: {
        refresh();
        root.sourceText = sourceFileView.text();
    }

    property QtObject _sourceFileView: FileView {
        id: sourceFileView
        path: KeybindsConfig.sourceFile
        blockLoading: true
        printErrors: false
        onLoaded: root.sourceText = sourceFileView.text()
    }

    property QtObject _proc: Process {
        id: proc
        command: ["hyprctl", "binds", "-j"]
        property string _buf: ""

        stdout: SplitParser {
            onRead: data => proc._buf += data + "\n"
        }

        onRunningChanged: {
            if (!running && _buf.length > 0) {
                root._apply(_buf);
                _buf = "";
            }
        }
    }

    function _apply(jsonText) {
        let raw;
        try {
            raw = JSON.parse(jsonText);
        } catch (e) {
            return;
        }

        const parsed = [];
        const submaps = {};

        for (const b of raw) {
            const bind = {
                key: b.key || "",
                keycode: b.keycode || 0,
                mouse: !!b.mouse,
                catchAll: !!b.catch_all,
                modmask: b.modmask || 0,
                mods: KB.modsFromMask(b.modmask || 0),
                dispatcher: b.dispatcher || "",
                arg: b.arg || "",
                submap: b.submap || "",
                locked: !!b.locked,
                release: !!b.release,
                repeat: !!b.repeat
            };
            bind.slotId = KB.slotIdFor(bind);
            parsed.push(bind);
            if (bind.submap)
                submaps[bind.submap] = true;
        }

        root.binds = parsed;
        root.submapNames = Object.keys(submaps).sort();
    }
}
