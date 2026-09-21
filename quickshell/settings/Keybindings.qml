pragma Singleton
import QtQuick
import Quickshell.Io
import "../common"

Item {
    id: root
    property var draft: ({shared: "ALT", actions: {}})
    property var catalog: []
    property bool ready: false
    property bool dirty: false
    property string message: ""
    property string error: ""
    readonly property bool running: worker.running
    function request(action) {
        if (running) return;
        error = ""; message = "";
        worker.command = ["python3", Settings.repo + "scripts/shell-keybindings.py", action];
        if (action === "apply") worker.command = worker.command.concat([JSON.stringify(draft)]);
        worker.operation = action;
        worker.running = true;
    }
    function changeShared(value) { draft = Object.assign({}, draft, {shared: value}); dirty = true; message = ""; }
    function changeAction(id, key, value) {
        const actions = Object.assign({}, draft.actions);
        const change = {}; change[key] = value;
        actions[id] = Object.assign({}, actions[id], change);
        draft = Object.assign({}, draft, {actions: actions}); dirty = true; message = "";
    }
    function display(id) {
        const action = draft.actions[id];
        if (!action || !action.enabled) return "Disabled";
        return (action.shared && draft.shared ? draft.shared + " + " : "") + action.key;
    }
    Process {
        id: worker
        property string operation: ""
        property string output: ""
        property string failure: ""
        onStarted: { output = ""; failure = ""; }
        stdout: StdioCollector { onStreamFinished: worker.output = text }
        stderr: StdioCollector { onStreamFinished: worker.failure = text.trim() }
        onExited: (code, status) => {
            if (code !== 0) { root.error = failure || "Shortcuts could not be saved"; return; }
            try {
                const data = JSON.parse(output);
                root.draft = data.config;
                root.catalog = data.catalog;
                root.message = data.message;
                root.ready = true;
                root.dirty = operation === "defaults";
            } catch (e) { root.error = "Could not read shortcuts: " + e; }
        }
    }
    Component.onCompleted: request("read")
}
