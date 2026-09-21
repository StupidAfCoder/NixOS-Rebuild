import QtQuick
import QtQuick.Layouts
import Quickshell
import "../common"

ColumnLayout {
    id: root
    required property var device
    property bool confirmForget: false
    spacing: 8
    RowLayout {
        Layout.fillWidth: true
        ColoredIcon { Layout.preferredWidth: 24; Layout.preferredHeight: 24; iconName: root.device.connected ? "bluetooth-connected.svg" : "bluetooth.svg"; tint: Colors.accent }
        ColumnLayout {
            Layout.fillWidth: true
            PixelText { Layout.fillWidth: true; text: root.device.name || root.device.address }
            PixelText { Layout.fillWidth: true; text: root.device.connected ? "Connected" : root.device.paired ? "Saved device" : "Ready to pair"; color: Colors.textOnSurfaceVariant }
        }
    }
    Flow {
        Layout.fillWidth: true; implicitHeight: childrenRect.height; spacing: 6
        PixelButton { visible: root.device.paired; text: root.device.connected ? "Disconnect" : "Connect"; onClicked: root.device.connected ? root.device.disconnect() : root.device.connect() }
        PixelButton { visible: !root.device.paired; text: "Pair…"; onClicked: Quickshell.execDetached(["blueman-manager"]) }
        PixelButton { visible: root.device.paired; text: root.device.trusted ? "Trusted" : "Trust"; checked: root.device.trusted; onClicked: root.device.trusted = !root.device.trusted }
        PixelButton { visible: root.device.paired; text: root.confirmForget ? "Confirm forget" : "Forget…"; danger: root.confirmForget; onClicked: { if (root.confirmForget) { root.device.forget(); root.confirmForget = false; } else root.confirmForget = true; } }
        PixelButton { visible: root.confirmForget; text: "Cancel"; onClicked: root.confirmForget = false }
    }
    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Colors.outlineVariant }
}
