import QtQuick
import Quickshell
import Quickshell.Io

// Entry point: instantiate once from shell.qml. Toggled via IPC, same
// pattern as Keytree/ImagePicker/Desktop/Reticle:
//   qs ipc call draw toggle
Scope {
    id: root

    IpcHandler {
        target: "draw"

        function toggle(): void {
            DrawStore.toggleVisible();
        }
        function show(): void {
            DrawStore.setVisible(true);
        }
        function hide(): void {
            DrawStore.setVisible(false);
        }
    }

    // DrawWindow is destroyed on hide, exactly like ReticleWindow's own
    // Loader{active: ReticleStore.visible} - the difference is DrawStore
    // has no persisted position/state to restore on the next open, so the
    // fresh DrawCanvas simply starts blank. That's what makes "clear when
    // toggled off" happen for free, with no explicit clear-on-hide call.
    Loader {
        active: DrawStore.visible
        sourceComponent: DrawWindow {}
    }
}
