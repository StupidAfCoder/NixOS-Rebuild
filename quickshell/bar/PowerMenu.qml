pragma Singleton
import Quickshell
import QtQuick

QtObject {
    id: root
    property bool shown: false
    function toggle() { shown = !shown }
    function hide() { shown = false }
}