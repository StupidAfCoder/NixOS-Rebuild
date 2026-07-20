import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import "."

Item {
    id: content
    implicitWidth: 220
    implicitHeight: bezel.height
    width: implicitWidth
    height: implicitHeight
    anchors.horizontalCenter: parent.horizontalCenter
    visible: true
    z: 6

    y: BatteryPanel.shown ? (parent.height - height + 2) : parent.height

    Behavior on y {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    readonly property bool hasBattery: UPower.displayDevice.ready && UPower.displayDevice.isLaptopBattery
    readonly property real pct: UPower.displayDevice.percentage
    readonly property bool charging: UPower.displayDevice.state === UPowerDeviceState.Charging

    Rectangle {
        id: bezel
        width: content.implicitWidth
        height: panelBox.height + 12
        color: "#13141c"
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
                color: "#565f89"
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
            color: "#1a1b26"
            antialiasing: false
            z: 0
            clip: true

            Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: "#414868"; z: 2 }
            Rectangle { anchors.left: parent.left; height: parent.height; width: 1; color: "#414868"; z: 2 }
            Rectangle { anchors.right: parent.right; height: parent.height; width: 1; color: "#414868"; z: 2 }

            Column {
                anchors.fill: parent
                spacing: 2
                z: 1
                Repeater {
                    model: Math.ceil(panelBox.height / 3)
                    delegate: Rectangle {
                        width: panelBox.width
                        height: 1
                        color: "#c0caf5"
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
                        width: 3; height: 10; antialiasing: false; color: "#565f89"
                        x: modelData.hFlip ? 7 : 0
                    }
                    Rectangle { width: 10; height: 3; antialiasing: false; color: "#565f89" }
                }
            }

            ColumnLayout {
                id: mainColumn
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6
                z: 4

                // ---- battery readout (hidden entirely on desktops) ----
                RowLayout {
                    visible: content.hasBattery
                    Layout.fillWidth: true
                    spacing: 8

                    // pixel battery shell with fill proportional to %
                    Item {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 12

                        Rectangle {
                            anchors.fill: parent
                            anchors.rightMargin: 2
                            color: "transparent"
                            border.color: "#565f89"
                            border.width: 1
                            antialiasing: false
                        }
                        Rectangle {
                            width: 2; height: 6
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            color: "#565f89"
                            antialiasing: false
                        }
                        Rectangle {
                            x: 2; y: 2
                            width: Math.max(0, (20 - 4) * content.pct)
                            height: 8
                            color: content.pct < 0.2 ? "#f7768e" : content.charging ? "#9ece6a" : "#7aa2f7"
                            antialiasing: false
                        }
                    }

                    Text {
                        text: Math.round(content.pct * 100) + "%" + (content.charging ? " \u26a1" : "")
                        color: "#c0caf5"
                        font.family: "Cozette"
                        font.pixelSize: 10
                        font.bold: true
                        Layout.fillWidth: true
                    }
                }

                Rectangle {
                    visible: content.hasBattery
                    Layout.fillWidth: true; height: 1; color: "#292e42"; antialiasing: false
                }

                Text {
                    visible: !content.hasBattery
                    text: "NO BATTERY \u00b7 DESKTOP"
                    color: "#565f89"
                    font.family: "Cozette"
                    font.pixelSize: 9
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 4
                }

                Text {
                    text: "POWER PROFILE"
                    color: "#a9b1d6"
                    font.family: "Cozette"
                    font.pixelSize: 9
                    font.letterSpacing: 1
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Repeater {
                        model: PowerProfileBackend.availableProfiles
                        delegate: Rectangle {
                            required property string modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 24
                            readonly property bool active: PowerProfileBackend.activeProfile === modelData
                            color: profArea.containsMouse ? "#1f2335" : "transparent"
                            border.color: active ? "#7aa2f7" : "#292e42"
                            border.width: 1
                            antialiasing: false

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 6
                                anchors.rightMargin: 6
                                spacing: 6

                                Rectangle {
                                    width: 6; height: 6
                                    color: active ? "#7aa2f7" : "#414868"
                                    antialiasing: false
                                }
                                Text {
                                    text: modelData.toUpperCase()
                                    color: active ? "#c0caf5" : "#a9b1d6"
                                    font.family: "Cozette"
                                    font.pixelSize: 9
                                    font.letterSpacing: 1
                                    Layout.fillWidth: true
                                }
                            }

                            MouseArea {
                                id: profArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: PowerProfileBackend.setProfile(modelData)
                            }
                        }
                    }

                    Text {
                        visible: PowerProfileBackend.availableProfiles.length === 0
                        text: "power-profiles-daemon not found"
                        color: "#414868"
                        font.family: "Cozette"
                        font.pixelSize: 8
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 4
                        Layout.bottomMargin: 4
                    }
                }
            }
        }
    }
}