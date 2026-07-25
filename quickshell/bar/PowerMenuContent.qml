import QtQuick
import QtQuick.Layouts
import Quickshell
import "."

Item {
    id: content
    implicitWidth: 200
    implicitHeight: bezel.height
    width: implicitWidth
    height: implicitHeight
    anchors.verticalCenter: parent.verticalCenter
    visible: true
    z: 6

    x: PowerMenu.shown ? (parent.width - width + 2) : parent.width

    Behavior on x {
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
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Colors.outlineVariant; z: 2 }

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

            MouseArea {
                anchors.fill: parent
                z: -1
                onClicked: {}
            }

            Repeater {
                model: [
                    { x: -1, y: -1, vFlip: false },
                    { x: -1, y: panelBox.height - 9, vFlip: true }
                ]
                delegate: Item {
                    x: modelData.x; y: modelData.y
                    width: 10; height: 10
                    z: 3
                    Rectangle { width: 3; height: 10; antialiasing: false; color: Colors.outline }
                    Rectangle {
                        width: 10; height: 3; antialiasing: false; color: Colors.outline
                        y: modelData.vFlip ? 7 : 0
                    }
                }
            }

            ColumnLayout {
                id: mainColumn
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6
                z: 4

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    color: Colors.shadow
                    antialiasing: false

                    Repeater {
                        model: [
                            { x: -1, y: -1, vFlip: false, hFlip: false },
                            { x: parent.width - 9, y: -1, vFlip: false, hFlip: true },
                            { x: -1, y: parent.height - 9, vFlip: true, hFlip: false },
                            { x: parent.width - 9, y: parent.height - 9, vFlip: true, hFlip: true }
                        ]
                        delegate: Item {
                            x: modelData.x; y: modelData.y
                            width: 10; height: 10
                            Rectangle {
                                width: 3; height: 10; antialiasing: false; color: Colors.outlineVariant
                                x: modelData.hFlip ? 7 : 0
                            }
                            Rectangle {
                                width: 10; height: 3; antialiasing: false; color: Colors.outlineVariant
                                y: modelData.vFlip ? 7 : 0
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "[ animation\ngoes here ]"
                        horizontalAlignment: Text.AlignHCenter
                        color: Colors.outlineVariant
                        font.family: "Cozette"
                        font.pixelSize: 9
                    }

                    Rectangle {
                        width: 2; height: 2
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 4
                        color: Colors.success
                        antialiasing: false

                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.15; duration: 700 }
                            NumberAnimation { to: 1.0; duration: 700 }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Colors.surfaceContainerHigh; antialiasing: false }

                PowerMenuRow { label: "LOCK"; iconName: "lock.svg"; Layout.fillWidth: true
                    onClicked: {
                        PowerMenu.hide()
                        Quickshell.execDetached(["hyprlock"])
                    }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: Colors.surfaceContainerHigh; antialiasing: false }

                PowerMenuRow { label: "LOGOUT"; iconName: "logout.svg"; Layout.fillWidth: true
                    onClicked: {
                        PowerMenu.hide()
                        Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.exit()"])
                    }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: Colors.surfaceContainerHigh; antialiasing: false }

                PowerMenuRow { label: "SLEEP"; iconName: "moon.svg"; Layout.fillWidth: true
                    onClicked: {
                        PowerMenu.hide()
                        Quickshell.execDetached(["systemctl", "suspend"])
                    }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: Colors.surfaceContainerHigh; antialiasing: false }

                PowerMenuRow { label: "REBOOT"; iconName: "reload.svg"; Layout.fillWidth: true
                    onClicked: {
                        PowerMenu.hide()
                        Quickshell.execDetached(["systemctl", "reboot"])
                    }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: Colors.surfaceContainerHigh; antialiasing: false }

                PowerMenuRow { label: "SHUTDOWN"; iconName: "power.svg"; accent: Colors.error; Layout.fillWidth: true
                    onClicked: {
                        PowerMenu.hide()
                        Quickshell.execDetached(["systemctl", "poweroff"])
                    }
                }
            }
        }
    }
}