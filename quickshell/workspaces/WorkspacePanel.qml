pragma Singleton
import QtQuick
import Quickshell.Io
import Quickshell.Hyprland
import "WorkspaceState.js" as State

Item {
    id: root
    property bool shown: false
    function toggle() { shown = !shown; if (shown) Hyprland.refreshToplevels(); }
    function hide() { shown = false; }
    function focusWorkspace(id) {
        const workspace = Hyprland.workspaces.values.find(w => w.id === id);
        if (State.isSpecial(workspace) && workspace.active) {
            const window = workspace.toplevels.values[0];
            if (window) focusWindow(window.address); else hide();
            return;
        }
        const command = State.focusWorkspace(id, Hyprland.workspaces.values);
        if (command) { hide(); Hyprland.dispatch(command); }
    }
    function focusWindow(address) {
        const command = State.focusWindow(address);
        if (command) { hide(); Hyprland.dispatch(command); }
    }
    IpcHandler { target: "workspaces"; function toggle(): void { root.toggle(); } }
}
