pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "../common"

Item {
    id: root
    property real percent: 1.0
    property real pendingPercent: -1
    property bool available: false
    property string lastError: ""
    readonly property string scriptPath: Settings.repo + "scripts/brightness-ctl.sh"
    function refresh() { if (!query.running && !setter.running) query.running = true; }
    function setBrightness(pct) {
        if (!available) return;
        percent = Math.max(.02, Math.min(1, pct));
        pendingPercent = percent;
        debounce.restart();
    }
    function applyPending() {
        if (setter.running || pendingPercent < 0) return;
        setter.command = ["bash", scriptPath, "set", String(Math.round(pendingPercent * 100))];
        pendingPercent = -1;
        setter.running = true;
    }
    Timer { id: debounce; interval: 100; onTriggered: root.applyPending() }
    Process {
        id: setter
        onExited: (code, status) => { root.lastError = code === 0 ? "" : "Brightness adjustment failed"; root.applyPending(); }
    }
    Process {
        id: query
        command: ["bash", root.scriptPath, "get"]
        stdout: StdioCollector {
            onStreamFinished: { const value = parseInt(text.trim()); if (!isNaN(value)) root.percent = Math.max(0, Math.min(1, value / 100)); }
        }
        onExited: (code, status) => { root.available = code === 0; root.lastError = code === 0 ? "" : "No controllable backlight/DDC display found"; }
    }
}
