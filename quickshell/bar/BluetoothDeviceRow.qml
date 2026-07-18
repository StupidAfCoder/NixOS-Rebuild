import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth

Item {
    id: root
    required property BluetoothDevice device

    width: parent ? parent.width : 240
    height: 36

    readonly property bool busy: device.pairing || device.state === BluetoothDeviceState.Connecting || device.state === BluetoothDeviceState.Disconnecting

    Rectangle {
        anchors.fill: parent
        color: rowArea.containsMouse ? "#232939" : "transparent"
        antialiasing: false
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 8

        Image {
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            source: Quickshell.iconPath(root.device.icon, true)
            smooth: false
        }

        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true

            Text {
                text: root.device.name
                color: root.device.connected ? "#7aa2f7" : "#c0caf5"
                font.family: "Cozette"
                font.pixelSize: 10
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Text {
                text: root.busy ? "working..." : root.device.connected ? "connected" : root.device.paired ? "paired" : "available"
                color: "#565f89"
                font.family: "Cozette"
                font.pixelSize: 8
            }
        }

        Text {
            visible: root.device.batteryAvailable
            text: Math.round(root.device.battery * 100) + "%"
            color: "#565f89"
            font.family: "Cozette"
            font.pixelSize: 8
        }

        Rectangle {
            Layout.preferredWidth: actionText.width + 12
            Layout.preferredHeight: 18
            color: "transparent"
            border.color: "#414868"
            border.width: 1
            antialiasing: false
            visible: !root.busy

            Text {
                id: actionText
                anchors.centerIn: parent
                text: root.device.paired ? (root.device.connected ? "disconnect" : "connect") : "pair"
                color: "#c0caf5"
                font.family: "Cozette"
                font.pixelSize: 8
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (!root.device.paired) root.device.pair();
                    else if (root.device.connected) root.device.disconnect();
                    else root.device.connect();
                }
            }
        }

        // --- Trust toggle, only for paired devices ---
        Text {
            visible: root.device.paired
            text: root.device.trusted ? "*" : "."
            color: root.device.trusted ? "#e0af68" : "#565f89"
            font.family: "Cozette"
            font.pixelSize: 11

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                onClicked: root.device.trusted = !root.device.trusted
            }
        }

        Text {
            visible: root.device.paired && !root.busy
            text: "x"
            color: "#e0af68"
            font.family: "Cozette"
            font.pixelSize: 10

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                onClicked: root.device.forget()
            }
        }
    }

    MouseArea {
        id: rowArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }
}