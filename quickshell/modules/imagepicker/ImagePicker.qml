import QtQuick
import Quickshell
import Quickshell.Io

// Entry point: instantiate once from shell.qml.
//   qs ipc call imagepicker toggle
Scope {
    id: root

    property bool open: false

    function toggle() {
        root.open = !root.open;
    }

    IpcHandler {
        target: "imagepicker"

        function toggle(): void {
            root.toggle();
        }
        function open(): void {
            root.open = true;
        }
        function close(): void {
            root.open = false;
        }
    }

    Loader {
        active: root.open
        sourceComponent: ImagePickerWindow {
            onDismissed: root.open = false
        }
    }
}
