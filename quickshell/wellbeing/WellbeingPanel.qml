pragma Singleton
import QtQuick
import Quickshell.Io
Item {
    id: root
    property bool shown: false
    function toggle() { shown = !shown; }
    function hide() { shown = false; }
    IpcHandler { target: "wellbeing"; function toggle(): void { root.toggle(); } }
}
