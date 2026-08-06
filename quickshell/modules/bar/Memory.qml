import QtQuick
import Quickshell.Io
import qs.modules.theme

Text {
    id: root

    property real usedKb: 0
    property real totalKb: 1
    readonly property string icon: String.fromCharCode(0xf1c0) // fa-database

    function fmt(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + "G";
    }

    text: root.icon + "  " + root.fmt(root.usedKb) + " / " + root.fmt(root.totalKb) +
          " (" + Math.round(100 * root.usedKb / root.totalKb) + "%)"
    color: Theme.text
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize

    FileView {
        id: meminfoFile
        path: "/proc/meminfo"
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            meminfoFile.reload();
            const text = meminfoFile.text();
            const total = Number(text.match(/MemTotal:\s+(\d+)/)?.[1] ?? 1);
            const available = Number(text.match(/MemAvailable:\s+(\d+)/)?.[1] ?? 0);
            root.totalKb = total;
            root.usedKb = total - available;
        }
    }
}
