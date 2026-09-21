pragma Singleton
import Quickshell.Io
import QtQuick

Item {
    id: root
    property bool shown: false
    function toggle() { shown = !shown; }
    function hide() { shown = false; }
    IpcHandler {
        target: "power"
        function toggle(): void { root.toggle(); }
    }
}
