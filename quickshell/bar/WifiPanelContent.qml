import QtQuick
import QtQuick.Layouts
import "."

Item {
    id: content
    implicitWidth: 300
    implicitHeight: bezel.height
    width: implicitWidth
    height: implicitHeight
    anchors.horizontalCenter: parent.horizontalCenter
    visible: true
    z: 6

    y: WifiPanel.shown ? (parent.height - height + 2) : parent.height

    Behavior on y {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    Rectangle {
        id: bezel
        width: content.implicitWidth
        height: panelBox.height + 12
        color: Colors.shadow
        antialiasing: false
        z: 0

        Repeater {
            model: [
                { x: 3, y: 3 }, { x: bezel.width - 5, y: 3 },
                { x: 3, y: bezel.height - 5 }, { x: bezel.width - 5, y: bezel.height - 5 }
            ]
            delegate: Rectangle {
                x: modelData.x; y: modelData.y
                width: 2; height: 2
                color: Colors.outline
                antialiasing: false
            }
        }

        Rectangle {
            id: panelBox
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 6
            width: bezel.width - 12
            height: mainColumn.implicitHeight + 20
            color: Colors.background
            Behavior on color { ColorAnimation { duration: 350; easing.type: Easing.OutCubic } }
            antialiasing: false
            z: 0
            clip: true

            Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Colors.outlineVariant; z: 2 }
            Rectangle { anchors.left: parent.left; height: parent.height; width: 1; color: Colors.outlineVariant; z: 2 }
            Rectangle { anchors.right: parent.right; height: parent.height; width: 1; color: Colors.outlineVariant; z: 2 }

            Column {
                anchors.fill: parent
                spacing: 2
                z: 1
                Repeater {
                    model: Math.ceil(panelBox.height / 3)
                    delegate: Rectangle {
                        width: panelBox.width
                        height: 1
                        color: Colors.textOnBackground
                        opacity: 0.02
                    }
                }
            }

            MouseArea { anchors.fill: parent; z: -1; onClicked: {} }

            Repeater {
                model: [
                    { x: -1, y: -1, hFlip: false },
                    { x: panelBox.width - 9, y: -1, hFlip: true }
                ]
                delegate: Item {
                    x: modelData.x; y: modelData.y
                    width: 10; height: 10
                    z: 3
                    Rectangle {
                        width: 3; height: 10; antialiasing: false; color: Colors.outline
                        x: modelData.hFlip ? 7 : 0
                    }
                    Rectangle { width: 10; height: 3; antialiasing: false; color: Colors.outline }
                }
            }

            ColumnLayout {
                id: mainColumn
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6
                z: 4

                // ---- current connection status card ----
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46
                    color: Colors.shadow
                    border.color: Colors.surfaceContainerHigh
                    border.width: 1
                    antialiasing: false

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 8

                        // ethernet glyph, hand-drawn from rectangles --
                        // no dependency on an ethernet.svg that may not
                        // exist in your pixelarticons set
                        Item {
                            visible: NetworkBackend.ethernetConnected
                            Layout.preferredWidth: 14
                            Layout.preferredHeight: 14
                            Rectangle { x: 5; y: 0; width: 4; height: 8; color: Colors.success; antialiasing: false }
                            Rectangle { x: 2; y: 8; width: 10; height: 2; color: Colors.success; antialiasing: false }
                            Rectangle { x: 0; y: 10; width: 2; height: 4; color: Colors.success; antialiasing: false }
                            Rectangle { x: 6; y: 10; width: 2; height: 4; color: Colors.success; antialiasing: false }
                            Rectangle { x: 12; y: 10; width: 2; height: 4; color: Colors.success; antialiasing: false }
                        }

                        ColoredIcon {
                            visible: !NetworkBackend.ethernetConnected
                            Layout.preferredWidth: 14
                            Layout.preferredHeight: 14
                            iconName: "wifi.svg"
                            tint: NetworkBackend.wifiConnected ? Colors.success : Colors.mutedOnBackground
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: NetworkBackend.ethernetConnected ? "WIRED"
                                    : NetworkBackend.wifiConnected ? NetworkBackend.connectedSsid
                                    : "NOT CONNECTED"
                                color: Colors.textOnBackground
                                font.family: "Cozette"
                                font.pixelSize: 9
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: NetworkBackend.ethernetConnected
                                    ? (NetworkBackend.ethernetIface + (NetworkBackend.ethernetIp !== "" ? " \u00b7 " + NetworkBackend.ethernetIp : ""))
                                    : NetworkBackend.wifiConnected
                                        ? (NetworkBackend.wifiIp !== "" ? NetworkBackend.wifiIp : "")
                                        : "no active connection"
                                color: Colors.mutedOnBackground
                                font.family: "Cozette"
                                font.pixelSize: 8
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Colors.surfaceContainerHigh; antialiasing: false }

                // ---- wifi radio row ----
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    opacity: NetworkBackend.busy ? 0.5 : 1.0

                    Text {
                        text: NetworkBackend.busy ? "WIRELESS ..." : "WIRELESS"
                        color: Colors.mutedOnBackground
                        font.family: "Cozette"
                        font.pixelSize: 9
                        font.letterSpacing: 1
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        color: scanArea.containsMouse ? Colors.surfaceContainer : "transparent"
                        border.color: Colors.outlineVariant
                        border.width: 1
                        antialiasing: false
                        opacity: NetworkBackend.wifiRadioEnabled && !NetworkBackend.busy ? 1.0 : 0.3

                        Text {
                            anchors.centerIn: parent
                            text: "\u21bb"
                            color: Colors.accent
                            font.pixelSize: 9
                        }
                        MouseArea {
                            id: scanArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: NetworkBackend.wifiRadioEnabled && !NetworkBackend.busy
                            onClicked: NetworkBackend.scan(true)
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 14
                        color: NetworkBackend.wifiRadioEnabled ? Colors.surfaceContainerHigh : Colors.surfaceContainerLow
                        border.color: NetworkBackend.wifiRadioEnabled ? Colors.accent : Colors.outlineVariant
                        border.width: 1
                        antialiasing: false

                        Rectangle {
                            width: 8; height: 8
                            y: 2
                            x: NetworkBackend.wifiRadioEnabled ? parent.width - width - 2 : 2
                            color: NetworkBackend.wifiRadioEnabled ? Colors.accent : Colors.outline
                            antialiasing: false
                            Behavior on x { NumberAnimation { duration: 120 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: NetworkBackend.busy ? Qt.ForbiddenCursor : Qt.PointingHandCursor
                            enabled: !NetworkBackend.busy
                            onClicked: NetworkBackend.setRadio(!NetworkBackend.wifiRadioEnabled)
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Colors.surfaceContainerHigh; antialiasing: false }

                Text {
                    visible: !NetworkBackend.wifiRadioEnabled
                    text: "wifi radio off"
                    color: Colors.mutedOnBackground
                    font.family: "Cozette"
                    font.pixelSize: 8
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 10
                    Layout.bottomMargin: 10
                }

                Text {
                    visible: NetworkBackend.wifiRadioEnabled && NetworkBackend.networks.length === 0
                    text: NetworkBackend.scanning ? "scanning..." : "no networks found"
                    color: Colors.mutedOnBackground
                    font.family: "Cozette"
                    font.pixelSize: 8
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 10
                    Layout.bottomMargin: 10
                }

                ListView {
                    visible: NetworkBackend.wifiRadioEnabled && NetworkBackend.networks.length > 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(NetworkBackend.networks.length * 26, 200)
                    clip: true
                    model: NetworkBackend.networks
                    delegate: WifiNetworkRow {}
                }
            }
        }
    }
}