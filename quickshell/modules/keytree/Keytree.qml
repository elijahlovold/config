import QtQuick
import Quickshell
import Quickshell.Io

// Entry point: instantiate once from shell.qml. Toggled via IPC so Hyprland
// can bind a key to it instead of spawning the old standalone binary, e.g.
//   qs ipc call keytree toggle default
//   qs ipc call keytree toggle stator
Scope {
    id: root

    property string activeConfig: ""

    function toggle(config) {
        const name = config && config.length > 0 ? config : "default";
        root.activeConfig = root.activeConfig === name ? "" : name;
    }

    function open(config) {
        root.activeConfig = config && config.length > 0 ? config : "default";
    }

    function close() {
        root.activeConfig = "";
    }

    IpcHandler {
        target: "keytree"

        function toggle(config: string): void {
            root.toggle(config);
        }
        function open(config: string): void {
            root.open(config);
        }
        function close(): void {
            root.close();
        }
    }

    Loader {
        active: root.activeConfig.length > 0
        sourceComponent: KeytreeWindow {
            configName: root.activeConfig
            onDismissed: root.close()
        }
    }
}
