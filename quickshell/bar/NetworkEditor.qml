pragma Singleton
import QtQuick
import Quickshell.Io
import "../common"

Item {
    id: root
    property string errorMessage: ""
    readonly property bool running: editor.running
    function open() {
        if (editor.running) return;
        errorMessage = "";
        editor.running = true;
    }
    Process {
        id: editor
        command: ["python3", Settings.repo + "scripts/network-editor.py"]
        stdout: SplitParser { onRead: data => { if (data.trim() === "started") WifiPanel.hide(); } }
        stderr: StdioCollector { onStreamFinished: { if (text.trim()) root.errorMessage = text.trim(); } }
        onExited: (code, status) => {
            if (code !== 0) {
                if (!root.errorMessage) root.errorMessage = "The connection editor could not open (exit " + code + ").";
                WifiPanel.shown = true;
            } else root.errorMessage = "";
        }
    }
}
