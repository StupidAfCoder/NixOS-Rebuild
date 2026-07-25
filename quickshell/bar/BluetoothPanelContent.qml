import QtQuick
import QtQuick.Layouts
import "."

Item {
    id: content
    implicitWidth: 280
    implicitHeight: 360
    width: implicitWidth
    height: implicitHeight
    anchors.horizontalCenter: parent.horizontalCenter
    visible: true   // stays "visible" always -- it's fully off-screen when hidden, so nothing draws or catches clicks anyway

    // resting position: tucked 2px into the bottom border (matches the
    // old bottomMargin: -2). Hidden position: slid down until the box
    // is entirely below the screen's bottom edge.
    y: BluetoothPanel.shown ? (parent.height - height + 2) : parent.height

    property bool everToggled: false
    Connections {
        target: BluetoothPanel
        function onShownChanged() { content.everToggled = true }
    }

    Behavior on y {
        enabled: content.everToggled
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    Rectangle {
        id: panelBox
        anchors.fill: parent
        color: Colors.background
        Behavior on color { ColorAnimation { duration: 350; easing.type: Easing.OutCubic } }
        antialiasing: false

        // border on three sides only -- the bottom edge blends into
        // the screen border strip instead of drawing its own seam
        Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Colors.outlineVariant }
        Rectangle { anchors.left: parent.left; height: parent.height; width: 1; color: Colors.outlineVariant }
        Rectangle { anchors.right: parent.right; height: parent.height; width: 1; color: Colors.outlineVariant }

        MouseArea { anchors.fill: parent } // eat clicks so they don't fall through to desktop

        Repeater {
            model: [
                { x: -1, y: -1, hFlip: false },
                { x: panelBox.width - 9, y: -1, hFlip: true }
            ]
            delegate: Item {
                x: modelData.x; y: modelData.y
                width: 10; height: 10
                Rectangle { width: 10; height: 3; antialiasing: false; color: Colors.outline }
                Rectangle {
                    width: 3; height: 10; antialiasing: false; color: Colors.outline
                    x: modelData.hFlip ? 7 : 0
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "Bluetooth"
                    color: Colors.textOnBackground
                    font.family: "Cozette"
                    font.pixelSize: 11
                    font.bold: true
                    Layout.fillWidth: true
                }

                Rectangle {
                    id: closeBtn
                    width: 16; height: 16
                    antialiasing: false
                    color: closeArea.containsMouse ? Colors.error : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "x"
                        color: closeArea.containsMouse ? Colors.background : Colors.warning
                        font.family: "Cozette"
                        font.pixelSize: 11
                        font.bold: closeArea.containsMouse
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: BluetoothPanel.hide()
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Rectangle {
                    Layout.preferredWidth: powerText.width + 12
                    Layout.preferredHeight: 18
                    color: "transparent"
                    border.color: Colors.outlineVariant
                    border.width: 1
                    antialiasing: false
                    visible: BluetoothPanel.adapter !== null

                    Text {
                        id: powerText
                        anchors.centerIn: parent
                        text: BluetoothPanel.adapter && BluetoothPanel.adapter.enabled ? "on" : "off"
                        color: BluetoothPanel.adapter && BluetoothPanel.adapter.enabled ? Colors.accent : Colors.mutedOnBackground
                        font.family: "Cozette"
                        font.pixelSize: 8
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: BluetoothPanel.adapter.enabled = !BluetoothPanel.adapter.enabled
                    }
                }

                Rectangle {
                    Layout.preferredWidth: scanRow.width + 16
                    Layout.preferredHeight: 18
                    color: "transparent"
                    border.color: Colors.outlineVariant
                    border.width: 1
                    antialiasing: false
                    visible: BluetoothPanel.adapter !== null && BluetoothPanel.adapter.enabled

                    RowLayout {
                        id: scanRow
                        anchors.centerIn: parent
                        spacing: 4

                        Rectangle {
                            width: 5; height: 5; antialiasing: false
                            color: BluetoothPanel.adapter && BluetoothPanel.adapter.discovering ? Colors.accent : Colors.outlineVariant
                            SequentialAnimation on opacity {
                                running: BluetoothPanel.adapter && BluetoothPanel.adapter.discovering
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.2; duration: 400 }
                                NumberAnimation { to: 1.0; duration: 400 }
                            }
                        }

                        Text {
                            text: BluetoothPanel.adapter && BluetoothPanel.adapter.discovering ? "scanning" : "scan"
                            color: BluetoothPanel.adapter && BluetoothPanel.adapter.discovering ? Colors.accent : Colors.textOnBackground
                            font.family: "Cozette"
                            font.pixelSize: 8
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: BluetoothPanel.adapter.discovering = !BluetoothPanel.adapter.discovering
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    visible: BluetoothPanel.connectedCount > 0
                    Layout.preferredWidth: connText.width + 10
                    Layout.preferredHeight: 16
                    color: Colors.accent
                    antialiasing: false

                    Text {
                        id: connText
                        anchors.centerIn: parent
                        text: BluetoothPanel.connectedCount + " connected"
                        color: Colors.background
                        font.family: "Cozette"
                        font.pixelSize: 8
                        font.bold: true
                    }
                }

                Text {
                    visible: BluetoothPanel.adapter && BluetoothPanel.adapter.devices.count > 0 && BluetoothPanel.connectedCount === 0
                    text: BluetoothPanel.adapter ? BluetoothPanel.adapter.devices.count + " known" : ""
                    color: Colors.mutedOnBackground
                    font.family: "Cozette"
                    font.pixelSize: 8
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Colors.outlineVariant; antialiasing: false }

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
                        model: BluetoothPanel.adapter ? BluetoothPanel.adapter.devices : []
                        delegate: BluetoothDeviceRow {
                            Layout.fillWidth: true
                            required property var modelData
                            device: modelData
                        }
                    }

                    Text {
                        visible: !BluetoothPanel.adapter || BluetoothPanel.adapter.devices.count === 0
                        text: BluetoothPanel.adapter === null ? "no adapter found" : "no devices -- try scan"
                        color: Colors.mutedOnBackground
                        font.family: "Cozette"
                        font.pixelSize: 9
                        Layout.topMargin: 12
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }
    z: 6
}