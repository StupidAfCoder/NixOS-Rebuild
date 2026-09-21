import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import "../common"

Sheet {
    id: root
    shown: BatteryPanel.shown
    title: "Energy"
    subtitle: hasBattery ? (charging ? "Charging" : "On battery") : "Desktop power profiles"
    preferredWidth: 390
    preferredHeight: 390
    onDismiss: BatteryPanel.hide()
    readonly property bool hasBattery: UPower.displayDevice.ready && UPower.displayDevice.isLaptopBattery
    readonly property bool charging: UPower.displayDevice.state === UPowerDeviceState.Charging
    readonly property real percent: UPower.displayDevice.percentage
    PixelText { visible: root.hasBattery; text: Math.round(root.percent * 100) + "%"; font.family: "Pixel Operator"; font.pixelSize: 52 }
    RowLayout {
        visible: root.hasBattery; Layout.fillWidth: true; spacing: 4
        Repeater { model: 10; Rectangle { required property int index; Layout.fillWidth: true; height: 22; color: index < Math.round(root.percent * 10) ? Colors.accent : Colors.surfaceContainerHigh } }
    }
    PixelText { text: "Power profile"; color: Colors.textOnSurfaceVariant }
    Flow {
        Layout.fillWidth: true; spacing: 6
        Repeater { model: PowerProfileBackend.availableProfiles; PixelButton { required property string modelData; text: modelData; primary: PowerProfileBackend.activeProfile === modelData; onClicked: PowerProfileBackend.setProfile(modelData) } }
    }
    PixelText { Layout.fillWidth: true; visible: !PowerProfileBackend.daemonAvailable; text: "Power profiles are unavailable on this system."; wrapMode: Text.Wrap; elide: Text.ElideNone }
}
