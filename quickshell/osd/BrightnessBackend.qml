pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root
    property real percent: 1.0
    property real pendingPercent: -1
    property string homeDir: ""
    readonly property string scriptPath: homeDir + "/.nixos_dotfiles/scripts/brightness-ctl.sh"

    function refresh() {
        if (root.homeDir === "")
            homeProc.running = true;
        else
            queryProc.running = true;
    }

    function setBrightness(pct) {
        pct = Math.max(0.02, Math.min(1, pct));
        root.percent = pct;
        root.pendingPercent = pct;
        debounce.restart();
    }

    property Process homeProc: Process {
        command: ["sh", "-c", "echo $HOME"]
        stdout: SplitParser {
            onRead: line => {
                root.homeDir = line.trim();
                queryProc.running = true;
            }
        }
    }

    property Timer debounce: Timer {
        interval: 180
        onTriggered: {
            if (root.pendingPercent < 0 || root.scriptPath === "")
                return;
            setProc.command = [root.scriptPath, "set", String(Math.round(root.pendingPercent * 100))];
            setProc.running = true;
            root.pendingPercent = -1;
        }
    }

    property Process setProc: Process {
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                console.log("brightness-ctl.sh set failed, exit code:", exitCode);
        }
    }

    property Process queryProc: Process {
        command: [root.scriptPath, "get"]
        stdout: SplitParser {
            onRead: line => {
                const val = parseInt(line.trim());
                if (!isNaN(val))
                    root.percent = val / 100.0;
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                console.log("brightness-ctl.sh get failed, exit code:", exitCode);
        }
    }
}
