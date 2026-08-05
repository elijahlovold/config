import Quickshell
import Quickshell.Io

// Entry point: instantiate once from shell.qml. Structural theme switch via
// IPC, same pattern as Keytree/ImagePicker/Desktop:
//   qs ipc call theme set Cyber
//   qs ipc call theme next
//   qs ipc call theme list
Scope {
    IpcHandler {
        target: "theme"

        function set(name: string): void {
            ThemeManager.setTheme(name);
        }
        function next(): void {
            ThemeManager.next();
        }
        function list(): string {
            return ThemeManager.themes.join(", ");
        }
    }
}
