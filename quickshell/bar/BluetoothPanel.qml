pragma Singleton
import Quickshell
import Quickshell.Wayland
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property bool shown: false
    function toggle() { shown = !shown }
    function hide() { shown = false }

    // must match ShellFrame's barWidth so the panel starts right where the bar ends
    property int barWidth: 40
    property int borderThickness: 8

    readonly property var adapter: Bluetooth.defaultAdapter

    PanelWindow {
        id: overlay
        visible: root.shown
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:bluetoothpanel"
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        mask: Region { item: panelBox }

        MouseArea {
            anchors.fill: parent
            onClicked: root.hide()
        }

        // --- The panel itself, flush against the true bottom so it visually
        // rises out of the bottom border strip instead of floating free ---
        Rectangle {
            id: panelBox
            anchors.left: parent.left
            anchors.leftMargin: root.barWidth
            anchors.bottom: parent.bottom
            width: 260
            height: 340
            color: "#1a1b26"
            border.color: "#414868"
            border.width: 1
            antialiasing: false

            MouseArea { anchors.fill: parent }

            // --- Pixel L-bracket corners, top only -- bottom corners
            // blend straight into the border strip below, so only the
            // top two need the bracket accent to read as "attached". ---
            Item {
                x: -1; y: -1
                width: 10; height: 10
                Rectangle { width: 10; height: 3; color: "#565f89"; antialiasing: false }
                Rectangle { width: 3; height: 10; color: "#565f89"; antialiasing: false }
            }
            Item {
                x: panelBox.width - 9; y: -1
                width: 10; height: 10
                Rectangle { x: 7; width: 3; height: 10; color: "#565f89"; antialiasing: false }
                Rectangle { width: 10; height: 3; color: "#565f89"; antialiasing: false }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                // --- Header ---
                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true

                        Text {
                            text: "Bluetooth"
                            color: "#c0caf5"
                            font.family: "Cozette"
                            font.pixelSize: 11
                            font.bold: true
                        }
                        Text {
                            text: root.adapter ? root.adapter.name : "no adapter"
                            color: "#565f89"
                            font.family: "Cozette"
                            font.pixelSize: 8
                        }
                    }

                    Text {
                        text: "x"
                        color: "#e0af68"
                        font.family: "Cozette"
                        font.pixelSize: 11
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            onClicked: root.hide()
                        }
                    }
                }

                // --- Power / scan toggles ---
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Rectangle {
                        Layout.preferredWidth: powerText.width + 12
                        Layout.preferredHeight: 18
                        color: "transparent"
                        border.color: "#414868"
                        border.width: 1
                        antialiasing: false
                        visible: root.adapter !== null

                        Text {
                            id: powerText
                            anchors.centerIn: parent
                            text: root.adapter && root.adapter.enabled ? "on" : "off"
                            color: root.adapter && root.adapter.enabled ? "#7aa2f7" : "#565f89"
                            font.family: "Cozette"
                            font.pixelSize: 8
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.adapter.enabled = !root.adapter.enabled
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: scanText.width + 12
                        Layout.preferredHeight: 18
                        color: "transparent"
                        border.color: "#414868"
                        border.width: 1
                        antialiasing: false
                        visible: root.adapter !== null && root.adapter.enabled

                        Text {
                            id: scanText
                            anchors.centerIn: parent
                            text: root.adapter && root.adapter.discovering ? "scanning" : "scan"
                            color: root.adapter && root.adapter.discovering ? "#7aa2f7" : "#c0caf5"
                            font.family: "Cozette"
                            font.pixelSize: 8
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.adapter.discovering = !root.adapter.discovering
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        visible: root.adapter && root.adapter.devices.count > 0
                        text: root.adapter ? root.adapter.devices.count + " known" : ""
                        color: "#565f89"
                        font.family: "Cozette"
                        font.pixelSize: 8
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#414868"; antialiasing: false }

                // --- Device list ---
                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentHeight: deviceList.height

                    ColumnLayout {
                        id: deviceList
                        width: parent.width
                        spacing: 2

                        Repeater {
                            model: root.adapter ? root.adapter.devices : []
                            delegate: BluetoothDeviceRow {
                                Layout.fillWidth: true
                                required property var modelData
                                device: modelData
                            }
                        }

                        Text {
                            visible: !root.adapter || root.adapter.devices.count === 0
                            text: root.adapter === null ? "no adapter found" : "no devices -- try scan"
                            color: "#565f89"
                            font.family: "Cozette"
                            font.pixelSize: 9
                            Layout.topMargin: 12
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }
        }
    }
}