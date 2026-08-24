pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root
    property string homeDir: ""
    readonly property string scriptPath: homeDir + "/.nixos_dotfiles/scripts/sysstats.sh"

    property int cpuPct: 0
    property int ramPct: 0
    property real ramUsedGb: 0
    property real ramTotalGb: 0
    property int gpuPct: -1
    property int gpuTemp: -1
    property int gpuMemUsed: 0
    property int gpuMemTotal: 0
    property int cpuTemp: -1

    Component.onCompleted: {
        if (root.homeDir === "")
            homeProc.running = true;
    }

    property Process homeProc: Process {
        command: ["sh", "-c", "echo $HOME"]
        stdout: SplitParser {
            onRead: line => {
                root.homeDir = line.trim();
                pollTimer.start();
                pollProc.running = true;
            }
        }
    }

    property Timer pollTimer: Timer {
        interval: 2000
        repeat: true
        onTriggered: pollProc.running = true
    }

    property Process pollProc: Process {
        command: root.scriptPath === "" ? [] : [root.scriptPath]
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
