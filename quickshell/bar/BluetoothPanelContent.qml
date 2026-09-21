pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Bluetooth
import "../common"

Sheet {
    id: root
    shown: BluetoothPanel.shown
    title: "Link cable"
    subtitle: "Bluetooth"
    preferredWidth: 410
    preferredHeight: mode === "scan" ? 600 : 520
    onDismiss: BluetoothPanel.hide()
    property string mode: "link"
    property string selectedAddress: ""
    property bool confirmForget: false
    property bool ownsDiscovery: false
    readonly property var adapter: BluetoothPanel.adapter
    readonly property var devices: adapter ? adapter.devices.values : []
    readonly property var device: devices.find(d => d.address === selectedAddress) || null
    readonly property var sortedDevices: [...devices].sort((a,b) => Number(b.connected)-Number(a.connected) || Number(b.paired)-Number(a.paired) || (a.name || a.address).localeCompare(b.name || b.address))
    function stopDiscovery() { if (ownsDiscovery && adapter) adapter.discovering = false; ownsDiscovery = false; }
    function scan() { mode = "scan"; if (adapter && !adapter.discovering) { adapter.discovering = true; ownsDiscovery = true; } }
    onShownChanged: {
        confirmForget = false;
        if (shown) {
            const connected = devices.find(d => d.connected);
            selectedAddress = connected?.address || "";
            mode = connected ? "link" : "scan";
        } else stopDiscovery();
    }
    Component.onDestruction: stopDiscovery()
    ConnectionScreen {
        Layout.fillWidth: true
        iconName: root.device?.connected ? "bluetooth-connected.svg" : "bluetooth.svg"
        online: root.device?.connected ?? false
        searching: root.adapter?.discovering ?? false
        status: !root.adapter ? "Unavailable" : root.adapter.discovering ? "Discovering" : root.device ? BluetoothDeviceState.toString(root.device.state) : "Standby"
        heading: root.device?.name || "Bluetooth"
        detail: root.device?.address || (root.adapter?.enabled ? "Select a device to link." : "Radio is off")
    }
    RowLayout {
        Layout.fillWidth: true
        TabButton { text: "Device"; selected: root.mode === "link"; enabled: !!root.device; onClicked: { root.mode = "link"; root.stopDiscovery(); } }
        TabButton { text: "Nearby"; selected: root.mode === "scan"; onClicked: root.mode = "scan" }
        Item { Layout.fillWidth: true }
        PixelButton { text: root.adapter?.enabled ? "Radio on" : "Radio off"; enabled: !!root.adapter; onClicked: root.adapter.enabled = !root.adapter.enabled }
    }
    ColumnLayout {
        visible: root.mode === "scan"; Layout.fillWidth: true; spacing: 8
        PixelButton { text: root.ownsDiscovery ? "Stop discovery" : root.adapter?.discovering ? "Discovery active" : "Discover devices"; enabled: (root.adapter?.enabled ?? false) && (root.ownsDiscovery || !root.adapter.discovering); onClicked: root.ownsDiscovery ? root.stopDiscovery() : root.scan() }
        ListView {
            id: list
            Layout.fillWidth: true; Layout.preferredHeight: 220; clip: true
            model: root.sortedDevices
            ScrollBar.vertical: ScrollBar {}
            delegate: MenuRow {
                required property var modelData
                width: list.width; label: modelData.name || modelData.address
                detail: modelData.connected ? "Connected" : modelData.paired ? "Saved device" : "Ready to pair"
                iconName: modelData.connected ? "bluetooth-connected.svg" : "bluetooth.svg"
                onClicked: { root.selectedAddress = modelData.address; root.mode = "link"; root.confirmForget = false; root.stopDiscovery(); root.resetScroll(); }
            }
            PixelText { visible: !list.count; anchors.centerIn: parent; text: "Discover to find nearby devices."; color: Colors.textOnSurfaceVariant }
        }
    }
    ColumnLayout {
        visible: root.mode === "link" && !!root.device; Layout.fillWidth: true; spacing: 16
        RowLayout {
            Layout.fillWidth: true
            PixelText { text: "Status"; Layout.fillWidth: true; color: Colors.textOnSurfaceVariant }
            PixelText { text: root.device ? BluetoothDeviceState.toString(root.device.state) : "" }
        }
        RowLayout {
            visible: root.device?.batteryAvailable ?? false; Layout.fillWidth: true
            PixelText { text: "Battery"; Layout.fillWidth: true; color: Colors.textOnSurfaceVariant }
            PixelText { text: Math.round((root.device?.battery || 0) * 100) + "%" }
        }
        Flow {
            Layout.fillWidth: true; spacing: 6
            PixelButton { text: root.device?.connected ? "Disconnect" : "Connect"; visible: root.device?.paired ?? false; enabled: root.adapter?.enabled ?? false; onClicked: root.device.connected ? root.device.disconnect() : root.device.connect() }
            PixelButton { text: "Pair in manager"; visible: !(root.device?.paired ?? false); onClicked: Quickshell.execDetached(["blueman-manager"]) }
            PixelButton { text: root.device?.trusted ? "Trusted" : "Trust"; visible: root.device?.paired ?? false; onClicked: root.device.trusted = !root.device.trusted }
            PixelButton { text: root.confirmForget ? "Confirm forget" : "Forget…"; visible: root.device?.paired ?? false; danger: root.confirmForget; onClicked: { if (root.confirmForget) { root.device.forget(); root.selectedAddress = ""; root.mode = "scan"; root.confirmForget = false; } else root.confirmForget = true; } }
            PixelButton { text: "Cancel"; visible: root.confirmForget; onClicked: root.confirmForget = false }
        }
        PixelText { visible: !(root.device?.paired ?? true); text: "PIN and passkey confirmation opens in Blueman."; Layout.fillWidth: true; wrapMode: Text.Wrap; color: Colors.textOnSurfaceVariant }
    }
}
