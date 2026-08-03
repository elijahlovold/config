import QtQuick
import Quickshell.Io
import qs.modules.common

// Reads amdgpu's sysfs ABI directly (/sys/class/drm/card1/device/) instead
// of shelling out to ~/waybar/scripts/amdgpu.sh - same FileView+Timer
// pattern as Cpu.qml/Memory.qml, no subprocess at all.
Text {
    id: root

    readonly property string devicePath: "/sys/class/drm/card1/device"
    readonly property string icon: String.fromCharCode(0xf108) // fa-desktop

    property int busyPercent: 0
    property real vramUsedGb: 0
    property real vramTotalGb: 1

    text: root.icon + "  " + root.busyPercent + "%  " + root.vramUsedGb.toFixed(1) + " / " + root.vramTotalGb.toFixed(1) + "G"
    color: Theme.text
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize

    FileView {
        id: busyFile
        path: root.devicePath + "/gpu_busy_percent"
    }
    FileView {
        id: vramUsedFile
        path: root.devicePath + "/mem_info_vram_used"
    }
    FileView {
        id: vramTotalFile
        path: root.devicePath + "/mem_info_vram_total"
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            // reload() is async - reading .text() back in the same tick
            // right after calling it returns last cycle's content, not this
            // one. Harmless for values that are already re-polled every
            // tick (they're perpetually "one interval behind", invisible at
            // this refresh rate) but fatal for a value only ever read once,
            // which is why vramTotal moved from a one-shot Component
            // .onCompleted read (where "one behind" meant "never correct")
            // into this recurring timer alongside the other two.
            busyFile.reload();
            vramUsedFile.reload();
            vramTotalFile.reload();
            root.busyPercent = parseInt(busyFile.text().trim()) || 0;
            root.vramUsedGb = Number(vramUsedFile.text().trim()) / (1024 * 1024 * 1024);
            root.vramTotalGb = Number(vramTotalFile.text().trim()) / (1024 * 1024 * 1024) || 1;
        }
    }
}
