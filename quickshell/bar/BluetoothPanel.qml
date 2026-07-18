pragma Singleton
import Quickshell
import Quickshell.Bluetooth
import QtQuick

QtObject {
    id: root
    property bool shown: false
    function toggle() { shown = !shown }
    function hide() { shown = false }

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property int connectedCount: adapter
        ? adapter.devices.values.filter(d => d.connected).length : 0
}