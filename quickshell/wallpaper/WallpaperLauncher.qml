pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    property bool shown: false
    function toggle() { shown = !shown }
    function hide() { shown = false }

    IpcHandler {
        target: "wallpaper"
        function toggle(): void { root.toggle() }
    }
}