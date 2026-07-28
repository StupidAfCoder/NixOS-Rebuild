pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool isOpen: false
    property string position: "top"
    property string query: ""
    property int selectedIndex: 0

    function toggle() {
        if (root.isOpen) {
            hide()
        } else {
            show()
        }
    }

    function show() {
        root.isOpen = true
        root.query = ""
        root.selectedIndex = 0
    }

    function hide() {
        root.isOpen = false
    }

    function setPosition(p) {
        if (p === "top" || p === "bottom" || p === "right")
            root.position = p
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void { root.toggle() }
        function show(): void { root.show() }
        function hide(): void { root.hide() }
        function setPosition(p: string): void { root.setPosition(p) }
    }
}