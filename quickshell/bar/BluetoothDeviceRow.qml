import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root
    required property var device
    spacing: 6
    height: 30

    // --- BlueZ hints the device type via its "icon" property
    // (audio-headset, phone, input-keyboard, input-mouse, input-gaming,
    // computer, printer...). Map to whatever's actually in your
    // pixelarticons set -- adjust freely, these are close-enough proxies. ---
    function iconForDevice(dev) {
        const hint = (dev && dev.icon) ? dev.icon : ""
        if (hint.indexOf("headset") !== -1 || hint.indexOf("headphone") !== -1) return "headphone.svg"
        if (hint.indexOf("phone") !== -1) return "smartphone.svg"
        if (hint.indexOf("mouse") !== -1) return "mouse.svg"
        if (hint.indexOf("gaming") !== -1 || hint.indexOf("joystick") !== -1) return "gamepad.svg"
        if (hint.indexOf("keyboard") !== -1) return "keyboard-music.svg" // no plain keyboard.svg in the free set
        if (hint.indexOf("printer") !== -1) return "printer.svg"
        if (hint.indexOf("computer") !== -1 || hint.indexOf("laptop") !== -1) return "computer.svg"
        return dev && dev.connected ? "bluetooth-connected.svg" : "bluetooth.svg"
    }

    ColoredIcon {
        Layout.preferredWidth: 14
        Layout.preferredHeight: 14
        iconName: root.iconForDevice(root.device)
        tint: root.device.connected ? Colors.accent : Colors.mutedOnBackground
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Text {
            text: root.device.name || root.device.address
            color: root.device.connected ? Colors.onBackground : Colors.mutedOnBackground
            font.family: "Cozette"
            font.pixelSize: 9
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        RowLayout {
            spacing: 4
            Text {
                text: root.device.connected ? "connected" : (root.device.paired ? "paired" : "available")
                color: root.device.connected ? Colors.success : Colors.mutedOnBackground
                font.family: "Cozette"
                font.pixelSize: 7
            }

            // --- pixel signal-strength bars, only when BlueZ actually
            // reports an RSSI (usually only during active discovery) ---
            RowLayout {
                visible: root.device.connected && root.device.rssi !== undefined && root.device.rssi !== 0
                spacing: 1
                Repeater {
                    model: 4
                    delegate: Rectangle {
                        antialiasing: false
                        width: 2
                        height: 2 + index * 2
                        color: {
                            const rssi = root.device.rssi || -90
                            const bars = rssi > -50 ? 4 : rssi > -65 ? 3 : rssi > -80 ? 2 : 1
                            return index < bars ? Colors.success : Colors.outlineVariant
                        }
                        Layout.alignment: Qt.AlignBottom
                    }
                }
            }
        }
    }

    // --- Trust toggle, only for paired devices ---
    Text {
        visible: root.device.paired
        text: root.device.trusted ? "*" : "."
        color: root.device.trusted ? Colors.warning : Colors.mutedOnBackground
        font.family: "Cozette"
        font.pixelSize: 11

        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            onClicked: root.device.trusted = !root.device.trusted
        }
    }

    // --- Connect / disconnect ---
    Rectangle {
        visible: root.device.paired
        Layout.preferredWidth: connectText.width + 10
        Layout.preferredHeight: 16
        color: "transparent"
        border.color: root.device.connected ? Colors.success : Colors.outlineVariant
        border.width: 1
        antialiasing: false

        Text {
            id: connectText
            anchors.centerIn: parent
            text: root.device.connected ? "disconnect" : "connect"
            color: root.device.connected ? Colors.success : Colors.onBackground
            font.family: "Cozette"
            font.pixelSize: 7
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.device.connected ? root.device.disconnect() : root.device.connect()
        }
    }

    // --- Pair (unpaired devices only) ---
    Rectangle {
        visible: !root.device.paired
        Layout.preferredWidth: pairText.width + 10
        Layout.preferredHeight: 16
        color: "transparent"
        border.color: Colors.outlineVariant
        border.width: 1
        antialiasing: false

        Text {
            id: pairText
            anchors.centerIn: parent
            text: "pair"
            color: Colors.onBackground
            font.family: "Cozette"
            font.pixelSize: 7
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.device.pair()
        }
    }

    // --- Forget button ---
    Text {
        visible: root.device.paired
        text: "del"
        color: Colors.error
        font.family: "Cozette"
        font.pixelSize: 7

        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            onClicked: root.device.forget()
        }
    }
}