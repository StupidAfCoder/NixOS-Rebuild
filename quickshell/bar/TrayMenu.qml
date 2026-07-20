pragma Singleton
import Quickshell
import QtQuick

QtObject {
    id: root
    property bool shown: false
    property var stack: []   // [{ handle, x, y }, ...]

    function openFor(item, x, y) {
        stack = [{ handle: item.menu, x: x, y: y }]
        shown = true
    }

    function openSubmenu(entry, x, y, level) {
        const newStack = stack.slice(0, level)
        newStack.push({ handle: entry, x: x, y: y })
        stack = newStack
    }

    function hide() {
        shown = false
        stack = []
    }
}