pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../common"

ColumnLayout {
    id: root
    spacing: 10
    IconButton {
        visible: Settings.moduleEnabled("battery")
        Layout.alignment: Qt.AlignHCenter
        readonly property bool hasBattery: UPower.displayDevice.ready && UPower.displayDevice.isLaptopBattery
        readonly property real percent: UPower.displayDevice.percentage
        iconName: hasBattery ? (percent < .2 ? "battery-low.svg" : percent < .6 ? "battery-medium.svg" : "battery-full.svg") : "battery-full.svg"
        hint: hasBattery ? "Battery · " + Math.round(percent * 100) + "%" : "Energy profiles"
        onClicked: BatteryPanel.toggle()
    }
    IconButton {
        visible: Settings.moduleEnabled("network")
        Layout.alignment: Qt.AlignHCenter
        iconName: NetworkBackend.ethernetOnline ? "app-windows.svg" : "wifi.svg"
        hint: NetworkBackend.ethernetOnline ? "Ethernet connected" : NetworkBackend.wifiConnected ? NetworkBackend.connectedSsid : "Network connections"
        onClicked: WifiPanel.toggle()
    }
    IconButton {
        visible: Settings.moduleEnabled("bluetooth") && Bluetooth.defaultAdapter !== null
        Layout.alignment: Qt.AlignHCenter
        iconName: !Bluetooth.defaultAdapter?.enabled ? "bluetooth-off.svg" : BluetoothPanel.connectedCount ? "bluetooth-connected.svg" : "bluetooth.svg"
        hint: "Bluetooth · " + BluetoothPanel.connectedCount + " connected"
        onClicked: BluetoothPanel.toggle()
    }
    IconButton {
        visible: Settings.moduleEnabled("tray") && TrayApps.items.length > 0
        Layout.alignment: Qt.AlignHCenter
        iconName: "chevron-right.svg"
        hint: "Background apps"
        checked: TrayApps.shown
        onClicked: TrayApps.toggle()
    }
    IconButton {
        visible: Settings.moduleEnabled("power")
        Layout.alignment: Qt.AlignHCenter
        iconName: "power.svg"; hint: "Session · Super+Ctrl+P"
        onClicked: PowerMenu.toggle()
    }
}
