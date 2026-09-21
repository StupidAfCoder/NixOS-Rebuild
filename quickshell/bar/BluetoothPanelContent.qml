import QtQuick
import QtQuick.Layouts
import Quickshell
import "../common"

Sheet {
    id: root
    shown: BluetoothPanel.shown
    title: "Bluetooth"
    subtitle: BluetoothPanel.adapter ? BluetoothPanel.connectedCount + " connected devices" : "No Bluetooth adapter"
    preferredWidth: 420
    preferredHeight: 560
    onDismiss: BluetoothPanel.hide()
    RowLayout {
        Layout.fillWidth: true
        PixelText { text: "Bluetooth radio"; Layout.fillWidth: true }
        PixelButton {
            text: BluetoothPanel.adapter?.enabled ? "On" : "Off"
            primary: BluetoothPanel.adapter?.enabled ?? false
            enabled: !!BluetoothPanel.adapter
            onClicked: BluetoothPanel.adapter.enabled = !BluetoothPanel.adapter.enabled
        }
    }
    PixelText { text: "Connected & saved"; color: Colors.textOnSurfaceVariant }
    Repeater {
        model: BluetoothPanel.adapter ? BluetoothPanel.adapter.devices.values.filter(d => d.paired || d.connected).sort((a,b) => Number(b.connected) - Number(a.connected)) : []
        BluetoothDeviceRow { required property var modelData; device: modelData; Layout.fillWidth: true }
    }
    PixelText { text: "Nearby devices"; color: Colors.textOnSurfaceVariant }
    PixelButton {
        text: BluetoothPanel.adapter?.discovering ? "Stop discovery" : "Discover devices"
        enabled: BluetoothPanel.adapter?.enabled ?? false
        onClicked: BluetoothPanel.adapter.discovering = !BluetoothPanel.adapter.discovering
    }
    Repeater {
        model: BluetoothPanel.adapter ? BluetoothPanel.adapter.devices.values.filter(d => !d.paired && !d.connected) : []
        BluetoothDeviceRow { required property var modelData; device: modelData; Layout.fillWidth: true }
    }
    PixelText { text: "Pairing codes and advanced options open in the Bluetooth manager."; Layout.fillWidth: true; wrapMode: Text.Wrap; elide: Text.ElideNone; color: Colors.textOnSurfaceVariant }
    PixelButton { text: "Bluetooth manager…"; onClicked: Quickshell.execDetached(["blueman-manager"]) }
}
