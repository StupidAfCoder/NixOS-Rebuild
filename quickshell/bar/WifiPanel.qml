pragma Singleton
import Quickshell
import QtQuick

QtObject {
    id: root
    property bool shown: false

    function toggle() {
        shown = !shown
        if (shown) {
            BluetoothPanel.hide()   // both panels anchor bottom-center -- avoid overlap
            NetworkBackend.refreshStatus()
            NetworkBackend.scan(false)
        }
    }
    function hide() { shown = false }
}