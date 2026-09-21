pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../common"

Sheet {
    id: root
    shown: WifiPanel.shown
    title: "Wireless"
    preferredWidth: 360
    preferredHeight: mode === "scan" ? 600 : mode === "join" ? 550 : 470
    onDismiss: WifiPanel.hide()
    property string mode: "link"
    property string selectedSsid: ""
    property bool secured: false
    property bool forgetConfirm: false
    readonly property var activeNetwork: NetworkBackend.networks.find(n => n.inUse) || null
    readonly property bool linked: NetworkBackend.wifiConnected || NetworkBackend.ethernetConnected
    function scan() { mode = "scan"; forgetConfirm = false; NetworkBackend.scan(true); resetScroll(); }
    onShownChanged: {
        password.text = ""; reveal.checked = false; forgetConfirm = false;
        if (shown) { mode = linked ? "link" : "scan"; NetworkBackend.scan(false); }
    }
    Connections { target: NetworkBackend; function onConnectedSsidChanged() { if (root.shown && NetworkBackend.wifiConnected) root.mode = "link"; } }
    ConnectionScreen {
        Layout.fillWidth: true
        iconName: "wifi.svg"
        online: root.linked
        searching: NetworkBackend.scanning
        status: root.mode === "join" ? "Connect" : NetworkBackend.scanning ? "Searching" : root.linked ? "Link ready" : "Standby"
        heading: root.mode === "join" ? root.selectedSsid : NetworkBackend.wifiConnected ? (root.activeNetwork?.ssid || NetworkBackend.connectedSsid) : NetworkBackend.ethernetConnected ? "Ethernet" : NetworkBackend.wifiRadioEnabled ? "Nearby signals" : "Radio off"
        detail: root.mode === "join" ? (root.secured ? "Secured network" : "Open network") : root.linked ? (NetworkBackend.wifiIp || NetworkBackend.ethernetIp || "Obtaining address…") : "Choose a network to connect."
    }
    RowLayout {
        Layout.fillWidth: true
        TabButton { text: "Link"; selected: root.mode === "link"; onClicked: { root.mode = "link"; root.forgetConfirm = false; } }
        TabButton { text: "Scan"; selected: root.mode === "scan"; enabled: NetworkBackend.wifiRadioEnabled && !!NetworkBackend.wifiIface; onClicked: root.scan() }
        Item { Layout.fillWidth: true }
        PixelButton { text: NetworkBackend.wifiRadioEnabled ? "Radio on" : "Radio off"; enabled: !NetworkBackend.busy && !!NetworkBackend.wifiIface; onClicked: NetworkBackend.setRadio(!NetworkBackend.wifiRadioEnabled) }
    }
    ColumnLayout {
        visible: root.mode === "link"; Layout.fillWidth: true; spacing: 14
        RowLayout {
            Layout.fillWidth: true
            PixelText { text: "Internet"; Layout.fillWidth: true; color: Colors.textOnSurfaceVariant }
            PixelText { text: NetworkBackend.connectivityState === "full" ? "Online" : NetworkBackend.connectivityState === "portal" ? "Sign-in required" : "Not confirmed" }
        }
        RowLayout {
            Layout.fillWidth: true; visible: NetworkBackend.wifiConnected && !!root.activeNetwork
            PixelText { text: "Signal"; Layout.fillWidth: true; color: Colors.textOnSurfaceVariant }
            SignalMeter { strength: root.activeNetwork?.signal || 0; Layout.preferredWidth: 28; Layout.preferredHeight: 16 }
            PixelText { text: (root.activeNetwork?.signal || 0) + "%" }
        }
        PixelText { text: NetworkBackend.wifiConnected ? (root.activeNetwork?.secured ? "Secured Wi-Fi" : "Wi-Fi") + " · " + NetworkBackend.wifiIface : NetworkBackend.ethernetConnected ? "Wired · " + NetworkBackend.ethernetIface : "No active connection"; Layout.fillWidth: true; color: Colors.textOnSurfaceVariant }
        Flow {
            Layout.fillWidth: true; spacing: 6
            PixelButton { text: "Disconnect"; visible: NetworkBackend.wifiConnected; enabled: !NetworkBackend.busy; onClicked: NetworkBackend.disconnectWifi() }
            PixelButton { text: root.forgetConfirm ? "Confirm forget" : "Forget…"; visible: NetworkBackend.wifiConnected; danger: root.forgetConfirm; enabled: !NetworkBackend.busy; onClicked: { if (root.forgetConfirm) { NetworkBackend.forgetNetwork(NetworkBackend.connectedSsid); root.forgetConfirm = false; } else root.forgetConfirm = true; } }
            PixelButton { visible: root.forgetConfirm; text: "Cancel"; onClicked: root.forgetConfirm = false }
            PixelButton { text: NetworkEditor.running ? "Editor open" : "Advanced…"; Accessible.name: "Edit Ethernet and Wi-Fi connections"; enabled: !NetworkEditor.running; onClicked: NetworkEditor.open() }
        }
    }
    ColumnLayout {
        visible: root.mode === "scan"; Layout.fillWidth: true; spacing: 8
        RowLayout {
            Layout.fillWidth: true
            PixelText { text: NetworkBackend.scanning ? "Searching nearby…" : NetworkBackend.networks.length + " networks"; Layout.fillWidth: true; color: Colors.textOnSurfaceVariant }
            PixelButton { text: "Scan again"; enabled: !NetworkBackend.scanning && NetworkBackend.wifiRadioEnabled; onClicked: root.scan() }
        }
        ListView {
            id: networks
            Layout.fillWidth: true; Layout.preferredHeight: 230; clip: true
            model: NetworkBackend.wifiRadioEnabled ? NetworkBackend.networks : []
            ScrollBar.vertical: ScrollBar {}
            delegate: MenuRow {
                required property var modelData
                width: networks.width
                label: modelData.ssid
                detail: modelData.inUse ? "Connected" : modelData.secured ? "Secured" : "Open network"
                trailing: modelData.signal + "%"
                selected: modelData.inUse
                onClicked: {
                    root.selectedSsid = modelData.ssid; root.secured = modelData.secured;
                    password.text = ""; reveal.checked = false; root.mode = modelData.inUse ? "link" : "join";
                    root.resetScroll();
                    if (root.mode === "join") Qt.callLater(function() { (root.secured ? password : connectButton).forceActiveFocus(); });
                }
            }
            PixelText { anchors.centerIn: parent; visible: networks.count === 0 && !NetworkBackend.scanning; text: !NetworkBackend.wifiIface ? "No Wi-Fi adapter" : NetworkBackend.wifiRadioEnabled ? "No signals found" : "Radio is off"; color: Colors.textOnSurfaceVariant }
        }
    }
    ColumnLayout {
        visible: root.mode === "join"; Layout.fillWidth: true; spacing: 14
        PixelField { id: password; Layout.fillWidth: true; visible: root.secured; placeholderText: "Password · blank for a saved network"; echoMode: reveal.checked ? TextInput.Normal : TextInput.Password; onAccepted: { if (NetworkBackend.busy) return; NetworkBackend.connectToNetwork(root.selectedSsid, text); text = ""; } }
        RowLayout {
            Layout.fillWidth: true
            PixelButton { id: reveal; visible: root.secured; text: checked ? "Hide password" : "Show password"; checkable: true }
            Item { Layout.fillWidth: true }
            PixelButton { text: "Back"; onClicked: { password.text = ""; root.mode = "scan"; } }
            PixelButton { id: connectButton; text: NetworkBackend.busy ? "Connecting…" : "Connect"; primary: true; enabled: !NetworkBackend.busy; onClicked: { NetworkBackend.connectToNetwork(root.selectedSsid, password.text); password.text = ""; } }
        }
    }
    PixelText { text: NetworkEditor.errorMessage; visible: !!text; Layout.fillWidth: true; wrapMode: Text.Wrap; elide: Text.ElideNone; color: Colors.error }
    PixelText { text: NetworkBackend.lastError; visible: !!text; Layout.fillWidth: true; wrapMode: Text.Wrap; elide: Text.ElideNone; color: Colors.error }
}
