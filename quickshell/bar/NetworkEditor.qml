pragma Singleton
import QtQuick
import Quickshell.Io
import "../common"

Item {
    id: root
    property string errorMessage: ""
    Timer { id: warningTimeout; interval: 7000; onTriggered: root.errorMessage = "" }
    Connections { target: WifiPanel; function onShownChanged() { if (!WifiPanel.shown) { root.errorMessage = ""; warningTimeout.stop(); } } }
    readonly property bool running: editor.running
    function open() {
        if (editor.running) return;
        warningTimeout.stop();
        errorMessage = "";
        editor.running = true;
    }
    Process {
        id: editor
        property string failure: ""
        onStarted: failure = ""
        command: ["python3", Settings.repo + "scripts/network-editor.py"]
        stdout: SplitParser { onRead: data => { if (data.trim() === "started") WifiPanel.hide(); } }
        stderr: StdioCollector { onStreamFinished: { editor.failure = text.trim(); } }
        onExited: (code, status) => {
            if (code !== 0) {
                root.errorMessage = editor.failure || "The connection editor could not open (exit " + code + ").";
                WifiPanel.shown = true;
                warningTimeout.restart();
            } else root.errorMessage = "";
        }
    }
}
