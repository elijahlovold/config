import QtQuick
import Quickshell.Io
import qs.modules.theme

Text {
    id: root

    readonly property string blocks: "▁▂▃▄▅▆▇█"
    readonly property string icon: String.fromCharCode(0xf2db) // fa-microchip

    property real usage: 0
    property var previousStats: null
    property var previousCoreStats: []
    property list<real> coreUsages: []

    text: root.icon + "  " + root.sparkline(root.coreUsages) + " " + Math.round(root.usage * 100) + "%"
    color: Theme.text
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize

    function sparkline(usages) {
        let s = "";
        for (const u of usages)
            s += root.blocks[Math.min(7, Math.max(0, Math.floor(u * 8)))];
        return s;
    }

    function parseCoreLines(text) {
        const cores = [];
        for (const line of text.split("\n")) {
            const m = line.match(/^cpu(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/);
            if (!m)
                continue;
            const stats = m.slice(2).map(Number);
            const total = stats.reduce((a, b) => a + b, 0);
            const idle = stats[3];
            cores.push({
                total,
                idle
            });
        }
        return cores;
    }

    FileView {
        id: statFile
        path: "/proc/stat"
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statFile.reload();
            const text = statFile.text();

            const aggMatch = text.match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/);
            if (aggMatch) {
                const stats = aggMatch.slice(1).map(Number);
                const total = stats.reduce((a, b) => a + b, 0);
                const idle = stats[3];
                if (root.previousStats) {
                    const totalDiff = total - root.previousStats.total;
                    const idleDiff = idle - root.previousStats.idle;
                    root.usage = totalDiff > 0 ? 1 - idleDiff / totalDiff : 0;
                }
                root.previousStats = {
                    total,
                    idle
                };
            }

            const cores = root.parseCoreLines(text);
            const usages = [];
            for (let i = 0; i < cores.length; i++) {
                const prev = root.previousCoreStats[i];
                if (prev) {
                    const totalDiff = cores[i].total - prev.total;
                    const idleDiff = cores[i].idle - prev.idle;
                    usages.push(totalDiff > 0 ? 1 - idleDiff / totalDiff : 0);
                } else {
                    usages.push(0);
                }
            }
            root.previousCoreStats = cores;
            root.coreUsages = usages;
        }
    }
}
