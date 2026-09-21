pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "../common"

QtObject {
    id: root
    readonly property string scriptPath: Settings.repo + "scripts/sysstats.sh"

    property int cpuPct: 0
    property int ramPct: 0
    property real ramUsedGb: 0
    property real ramTotalGb: 0
    property int gpuPct: -1
    property int gpuTemp: -1
    property int gpuMemUsed: 0
    property int gpuMemTotal: 0
    property int cpuTemp: -1

    property Timer pollTimer: Timer {
        interval: 2000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: pollProc.running = true
    }

    property Process pollProc: Process {
        command: root.scriptPath === "" ? [] : ["bash", root.scriptPath]
        stdout: SplitParser {
            onRead: line => {
                const p = line.trim().split(",");
                if (p.length < 9)
                    return;
                root.cpuPct = parseInt(p[0]) || 0;
                root.ramPct = parseInt(p[1]) || 0;
                root.ramUsedGb = parseFloat(p[2]) || 0;
                root.ramTotalGb = parseFloat(p[3]) || 0;
                root.gpuPct = parseInt(p[4]);
                root.gpuTemp = parseInt(p[5]);
                root.gpuMemUsed = parseInt(p[6]) || 0;
                root.gpuMemTotal = parseInt(p[7]) || 0;
                root.cpuTemp = parseInt(p[8]);
            }
        }
    }
}
