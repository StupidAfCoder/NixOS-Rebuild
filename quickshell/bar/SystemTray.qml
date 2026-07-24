import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.UPower
import Quickshell.Bluetooth
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts
import QtQuick.Window

ColumnLayout {
    id: root
    spacing: 12

    readonly property int iconSize: 16
    readonly property color glowColor: Colors.accent
    readonly property color dimColor: Colors.outline
    readonly property color warnColor: Colors.warning

    readonly property var trayFallback: ({
        "udiskie": "database.svg"
    })
    // apps that already have a dedicated indicator elsewhere in the bar --
    // don't show their raw tray icon too
    readonly property var trayHidden: ["blueman"]

    // ---------------- Battery ----------------
    Item {
        Layout.alignment: Qt.AlignHCenter
        width: root.iconSize + 4; height: root.iconSize + 4

        readonly property bool hasBattery: UPower.displayDevice.ready && UPower.displayDevice.isLaptopBattery
        readonly property real pct: UPower.displayDevice.percentage
        readonly property bool charging: UPower.displayDevice.state === UPowerDeviceState.Charging

        ColoredIcon {
            anchors.centerIn: parent
            width: root.iconSize; height: root.iconSize
            visible: parent.hasBattery
            iconName: parent.pct < 0.2 ? "battery-low.svg" : parent.pct < 0.6 ? "battery-medium.svg" : "battery-full.svg"
            tint: parent.pct < 0.2 ? root.warnColor : root.glowColor
        }
        ColoredIcon {
            anchors.centerIn: parent
            width: root.iconSize; height: root.iconSize
            visible: !parent.hasBattery
            iconName: "cancel.svg"
            tint: root.dimColor
        }

        MouseArea {
            id: battArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: BatteryPanel.toggle()
        }
        Rectangle {
            visible: battArea.containsMouse && !parent.hasBattery
            anchors.left: parent.right
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            width: tipText.width + 12
            height: tipText.height + 8
            color: Colors.background
            border.color: Colors.outlineVariant
            border.width: 1
            Text {
                id: tipText
                anchors.centerIn: parent
                text: "No battery detected"
                color: Colors.onSurface
                font.family: "Cozette"
                font.pixelSize: 10
            }
        }
    }

    // ---------------- Network ----------------
    Item {
        id: netItem
        Layout.alignment: Qt.AlignHCenter
        width: root.iconSize + 4; height: root.iconSize + 4

        Item {
            anchors.centerIn: parent
            width: root.iconSize; height: root.iconSize
            visible: NetworkBackend.ethernetOnline

            Rectangle { x: 6; y: 0; width: 4; height: 9; color: root.glowColor; antialiasing: false }
            Rectangle { x: 2; y: 9; width: 12; height: 2; color: root.glowColor; antialiasing: false }
            Rectangle { x: 0; y: 11; width: 2; height: 5; color: root.glowColor; antialiasing: false }
            Rectangle { x: 7; y: 11; width: 2; height: 5; color: root.glowColor; antialiasing: false }
            Rectangle { x: 14; y: 11; width: 2; height: 5; color: root.glowColor; antialiasing: false }
        }

        ColoredIcon {
            anchors.centerIn: parent
            width: root.iconSize; height: root.iconSize
            visible: !NetworkBackend.ethernetOnline
            iconName: "wifi.svg"
            tint: NetworkBackend.wifiConnected ? root.glowColor : root.dimColor
        }

        MouseArea {
            anchors.fill: parent
            onClicked: WifiPanel.toggle()
        }
    }
    // ---------------- Bluetooth ----------------
    Item {
        Layout.alignment: Qt.AlignHCenter
        width: root.iconSize + 4; height: root.iconSize + 4
        visible: Bluetooth.defaultAdapter !== null

        readonly property bool powered: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
        readonly property bool anyConnected: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.devices.values.some(d => d.connected)

        ColoredIcon {
            anchors.centerIn: parent
            width: root.iconSize; height: root.iconSize
            iconName: !parent.powered ? "bluetooth-off.svg" : parent.anyConnected ? "bluetooth-connected.svg" : "bluetooth.svg"
            tint: parent.powered ? root.glowColor : root.dimColor
        }

        MouseArea {
            anchors.fill: parent
            onClicked: BluetoothPanel.toggle()
        }
    }

    // ---------------- Extra app tray icons ----------------
    Repeater {
        model: SystemTray.items.values.filter(item => !root.trayHidden.includes(item.id))
        delegate: Item {
            id: trayIconRoot
            required property var modelData
            Layout.alignment: Qt.AlignHCenter
            width: root.iconSize + 4; height: root.iconSize + 4

            readonly property bool overridden: modelData.id in root.trayFallback

            IconImage {
                anchors.centerIn: parent
                implicitSize: root.iconSize
                asynchronous: true
                source: modelData.icon
                visible: !parent.overridden
            }
            ColoredIcon {
                anchors.centerIn: parent
                width: root.iconSize; height: root.iconSize
                visible: parent.overridden
                iconName: root.trayFallback[modelData.id] || ""
                tint: root.dimColor
            }

            MouseArea {
                id: trayArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: (mouse) => {
                    if (mouse.button === Qt.LeftButton) {
                        modelData.activate()
                    } else if (mouse.button === Qt.RightButton && modelData.hasMenu) {
                        const pos = mapToItem(null, mouse.x, mouse.y)
                        TrayMenu.openFor(modelData, pos.x, pos.y)
                    }
                }
            }

            Rectangle {
                visible: trayArea.containsMouse && modelData.hasMenu
                anchors.left: parent.right
                anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                width: trayTip.width + 12
                height: trayTip.height + 8
                color: Colors.background
                border.color: Colors.outlineVariant
                border.width: 1
                z: 20
                Text {
                    id: trayTip
                    anchors.centerIn: parent
                    text: "right-click for options"
                    color: Colors.onSurface
                    font.family: "Cozette"
                    font.pixelSize: 10
                }
            }
        }
    }

    // ---------------- Power button ----------------
    Item {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 6
        width: root.iconSize + 4; height: root.iconSize + 4

        ColoredIcon {
            anchors.centerIn: parent
            width: root.iconSize; height: root.iconSize
            iconName: "power.svg"
            tint: root.glowColor
        }
        MouseArea {
            anchors.fill: parent
            onClicked: PowerMenu.toggle()
        }
    }
}