pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.UPower
import Quickshell.Bluetooth
import Quickshell.Services.SystemTray as TrayService
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../common"

ColumnLayout {
    id: root
    spacing: 10
    readonly property var extraItems: TrayService.SystemTray.items.values.filter(item => item.id !== "blueman")
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
    Repeater {
        model: Settings.moduleEnabled("tray") ? root.extraItems : []
        IconButton {
            id: trayButton
            required property var modelData
            Layout.alignment: Qt.AlignHCenter
            hint: (modelData.title || modelData.id || "Application") + " · right-click for menu"
            contentItem: Item {
                ColoredIcon { anchors.fill: parent; iconName: "app-windows.svg"; tint: Colors.accent; visible: appIcon.status !== Image.Ready }
                IconImage { id: appIcon; anchors.fill: parent; source: trayButton.modelData.icon; asynchronous: true }
            }
            onClicked: modelData.activate()
            function openMenu() {
                if (!modelData.hasMenu) return;
                const position = mapToItem(null, width, height / 2);
                TrayMenu.openFor(modelData, position.x, position.y);
            }
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.RightButton; onClicked: trayButton.openMenu() }
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Menu || (event.key === Qt.Key_F10 && (event.modifiers & Qt.ShiftModifier))) {
                    openMenu(); event.accepted = true;
                }
            }
        }
    }
    IconButton {
        visible: Settings.moduleEnabled("power")
        Layout.alignment: Qt.AlignHCenter
        iconName: "power.svg"; hint: "Session · Super+Ctrl+P"
        onClicked: PowerMenu.toggle()
    }
}
