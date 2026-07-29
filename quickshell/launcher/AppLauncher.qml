pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    property bool shown: false

    function toggle() {
        shown = !shown;
    }
    function show() {
        shown = true;
    }
    function hide() {
        shown = false;
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            root.toggle();
        }
        function show(): void {
            root.show();
        }
        function hide(): void {
            root.hide();
        }
    }
}
