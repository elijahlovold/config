import QtQuick
import Quickshell
import Quickshell.Io

// Entry point: instantiate once from shell.qml. Same shape as
// Keytree/ImagePicker's entry points:
//   qs ipc call clipboard toggle
Scope {
    id: root

    property bool open: false

    function toggle() {
        root.open = !root.open;
    }

    IpcHandler {
        target: "clipboard"

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

    // Fresh ClipboardWindow instance every open (not active: false hiding a
    // persistent one) so cliphist list only ever runs while actually open -
    // same reasoning as every right-click popupComponent in modules/bar/.
    Loader {
        active: root.open
        sourceComponent: ClipboardWindow {
            onDismissed: root.open = false
        }
    }
}
