pragma Singleton
import Quickshell
import QtQuick

QtObject {
    id: root
    property bool shown: false

    function toggle() {
        shown = !shown
        if (shown) {
            BluetoothPanel.hide()
            WifiPanel.hide()
            BatteryPanel.hide()
        }
    }
    function hide() { shown = false }
}