import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../common"

Sheet {
    id: root
    shown: WifiPanel.shown
    title: "Wi-Fi"
    subtitle: NetworkBackend.wifiConnected ? "Connected · " + NetworkBackend.connectedSsid : "Not connected"
    preferredWidth: 390
    preferredHeight: 560
    property string selectedSsid: ""
    property bool secured: false
    property bool forgetConfirm: false
    onDismiss: WifiPanel.hide()
    onShownChanged: { if (shown) NetworkBackend.scan(false); else { password.text = ""; selectedSsid = ""; forgetConfirm = false; } }
    RowLayout {
        Layout.fillWidth: true
        PixelText { text: "Wi-Fi radio"; Layout.fillWidth: true }
        PixelButton { text: NetworkBackend.wifiRadioEnabled ? "On" : "Off"; primary: NetworkBackend.wifiRadioEnabled; enabled: !NetworkBackend.busy; onClicked: NetworkBackend.setRadio(!NetworkBackend.wifiRadioEnabled) }
    }
    Rectangle {
        Layout.fillWidth: true; implicitHeight: summary.implicitHeight + 28; color: Colors.surfaceContainerHigh
        Rectangle { width: 3; height: parent.height; color: Colors.accent }
        ColumnLayout {
            id: summary; anchors.fill: parent; anchors.margins: 14
            PixelText { Layout.fillWidth: true; text: NetworkBackend.wifiConnected ? NetworkBackend.connectedSsid : NetworkBackend.ethernetConnected ? "Ethernet connected" : "No active connection" }
            PixelText { Layout.fillWidth: true; text: (NetworkBackend.wifiIp || NetworkBackend.ethernetIp || "No address") + " · " + NetworkBackend.connectivityState; color: Colors.textOnSurfaceVariant }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        PixelText { text: "Nearby networks"; Layout.fillWidth: true; color: Colors.textOnSurfaceVariant }
        PixelButton { text: NetworkBackend.scanning ? "Scanning…" : "Refresh"; enabled: NetworkBackend.wifiRadioEnabled && !NetworkBackend.scanning; onClicked: NetworkBackend.scan(true) }
    }
    Repeater {
        model: NetworkBackend.wifiRadioEnabled ? NetworkBackend.networks : []
        PixelButton {
            required property var modelData
            Layout.fillWidth: true
            text: (modelData.inUse ? "✓ " : "") + modelData.ssid + " · " + modelData.signal + "% · " + (modelData.secured ? "secured" : "open")
            enabled: !NetworkBackend.busy
            onClicked: { root.selectedSsid = modelData.ssid; root.secured = modelData.secured; password.text = ""; }
        }
    }
    PixelText { visible: !NetworkBackend.wifiRadioEnabled; text: "Turn Wi-Fi on to discover networks."; Layout.fillWidth: true; wrapMode: Text.Wrap }
    ColumnLayout {
        visible: root.selectedSsid.length > 0; Layout.fillWidth: true
        PixelText { text: "Connect to " + root.selectedSsid; Layout.fillWidth: true }
        PixelField { id: password; Layout.fillWidth: true; visible: root.secured; placeholderText: "Password (blank for saved network)"; echoMode: reveal.checked ? TextInput.Normal : TextInput.Password }
        PixelButton { id: reveal; visible: root.secured; checkable: true; text: checked ? "Hide password" : "Show password" }
        RowLayout {
            PixelButton { text: NetworkBackend.busy ? "Connecting…" : "Connect"; primary: true; enabled: !NetworkBackend.busy; onClicked: { NetworkBackend.connectToNetwork(root.selectedSsid, password.text); password.text = ""; } }
            PixelButton { text: "Cancel"; onClicked: { root.selectedSsid = ""; password.text = ""; } }
        }
    }
    Flow {
        Layout.fillWidth: true; spacing: 6
        PixelButton { text: "Disconnect"; visible: NetworkBackend.wifiConnected; enabled: !NetworkBackend.busy; onClicked: NetworkBackend.disconnectWifi() }
        PixelButton { text: root.forgetConfirm ? "Confirm forget" : "Forget connection…"; danger: root.forgetConfirm; visible: NetworkBackend.wifiConnected; enabled: !NetworkBackend.busy; onClicked: { if (root.forgetConfirm) { NetworkBackend.forgetNetwork(NetworkBackend.connectedSsid); root.forgetConfirm = false; } else root.forgetConfirm = true; } }
        PixelButton { text: "Advanced…"; onClicked: Quickshell.execDetached(["nm-connection-editor"]) }
    }
    PixelText { text: NetworkBackend.lastError; visible: text.length > 0; color: Colors.error; wrapMode: Text.Wrap; elide: Text.ElideNone; Layout.fillWidth: true }
}
