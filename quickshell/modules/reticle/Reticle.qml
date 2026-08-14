import QtQuick
import Quickshell
import Quickshell.Io

// Entry point: instantiate once from shell.qml. Toggled via IPC, same
// pattern as Keytree/ImagePicker/Desktop:
//   qs ipc call reticle toggle
//   qs ipc call reticle edit
//   qs ipc call reticle style   (cycle Cross/Dot/Circle/Chevron/Brackets)
//   qs ipc call reticle color   (cycle the high-contrast color palette)
//   qs ipc call reticle outline (toggle the dark contrast stroke)
Scope {
    id: root

    IpcHandler {
        target: "reticle"

        function toggle(): void {
            ReticleStore.toggleVisible();
        }
        function show(): void {
            ReticleStore.setVisible(true);
        }
        function hide(): void {
            ReticleStore.setVisible(false);
        }
        function edit(): void {
            ReticleStore.toggleEditMode();
        }
        function style(): void {
            ReticleStore.cycleStyle();
        }
        function color(): void {
            ReticleStore.cycleColor();
        }
        function outline(): void {
            ReticleStore.toggleOutlined();
        }
    }

    // Stays instantiated (just internally invisible) across editMode
    // toggles, matching DesktopOverlayWindow's convention.
    Loader {
        active: ReticleStore.visible
        sourceComponent: ReticleWindow {}
    }

    Loader {
        active: ReticleStore.editMode
        sourceComponent: ReticleEditOverlay {}
    }
}
