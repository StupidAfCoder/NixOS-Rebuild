import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import QtQuick.Effects
import "pathgen.js" as PathGen
import "."

Item {
    id: root
    property int barWidth: 32

    width: barWidth

    readonly property var wsIcons: [
        "globe.svg", "terminal.svg", "message.svg", "music.svg", "braces.svg"
    ]

    BarShell {
        id: shell
        anchors.fill: parent
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 12
        anchors.bottomMargin: 12
        anchors.rightMargin: 4
        spacing: 8

        // --- NixOS logo / power button ---
        Item {
            Layout.alignment: Qt.AlignHCenter
            width: 24
            height: 24

            Image {
                anchors.centerIn: parent
                width: 14
                height: 14
                source: "file:///home/swami/.nixos_dotfiles/quickshell/bar/assets/NixOS.svg"
                smooth: false
            }

            MouseArea {
                anchors.fill: parent
                onClicked: console.log("power button clicked")
            }
        }

        // --- Workspace indicators ---
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 4

            Repeater {
                model: 5

                Item {
                    id: wsPill
                    required property int index
                    property int wsId: index + 1
                    property var wsData: Hyprland.workspaces.values.find(w => w.id === wsId)
                    property bool isActive: Hyprland.focusedWorkspace?.id === wsId
                    property bool isOccupied: !!wsData

                    width: 20
                    height: 20

                    readonly property var staticDots: [
                        {x: 1, y: 2}, {x: 14, y: 1}, {x: 4, y: 15},
                        {x: 16, y: 12}, {x: 9, y: 8}, {x: 2, y: 10}
                    ]

                    Repeater {
                        model: (!wsPill.isActive && !wsPill.isOccupied) ? wsPill.staticDots : []
                        delegate: Rectangle {
                            required property var modelData
                            x: wsPill.width / 2 - 9 + modelData.x
                            y: wsPill.height / 2 - 9 + modelData.y
                            width: 2
                            height: 2
                            color: "#e0af68"
                            opacity: 0.85
                            antialiasing: false
                        }
                    }

                    Rectangle {
                        visible: !wsPill.isActive && wsPill.isOccupied
                        anchors.centerIn: parent
                        width: 4
                        height: 4
                        color: "#7982a9"
                        antialiasing: false
                    }

                    Shape {
                        anchors.fill: parent
                        antialiasing: false
                        visible: wsPill.isActive
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            fillColor: "#7aa2f7"
                            strokeColor: "transparent"
                            PathSvg { path: PathGen.chamferedRectPath(20, 20, 6) }
                        }
                    }

                    Image {
                        id: wsIconImg
                        anchors.centerIn: parent
                        width: 13
                        height: 13
                        source: "file:///home/swami/.local/share/pixelarticons/svg/" + root.wsIcons[wsPill.index]
                        smooth: false
                        visible: false
                    }

                    MultiEffect {
                        anchors.fill: wsIconImg
                        source: wsIconImg
                        visible: wsPill.isActive
                        colorization: 1.0
                        colorizationColor: "#1a1b26"
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            Hyprland.dispatch('hl.dsp.focus({ workspace = "' + wsPill.wsId + '" })')
                        }
                    }
                }
            }
        }

        BarDivider { Layout.alignment: Qt.AlignHCenter; barWidth: 32 }

        Item {
            id: middleZone
            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: true
            width: 24

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 10
                anchors.bottomMargin: 8
                spacing: 0

                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8

                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 1

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.formatDateTime(clockTimer.now, "hh")
                            color: "#c0caf5"
                            font.family: "Pixel Operator"
                            font.pixelSize: 14
                            font.bold: true
                            renderType: Text.NativeRendering
                            horizontalAlignment: Text.AlignHCenter
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.formatDateTime(clockTimer.now, "mm")
                            color: "#c0caf5"
                            font.family: "Pixel Operator"
                            font.pixelSize: 14
                            font.bold: true
                            renderType: Text.NativeRendering
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 16
                        height: 1
                        color: "#414868"
                        antialiasing: false
                    }

                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 2

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.formatDateTime(clockTimer.now, "dd")
                            color: "#c0caf5"
                            font.family: "Cozette"
                            font.pixelSize: 9
                            renderType: Text.NativeRendering
                            horizontalAlignment: Text.AlignHCenter
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.formatDateTime(clockTimer.now, "MM")
                            color: "#c0caf5"
                            font.family: "Cozette"
                            font.pixelSize: 9
                            renderType: Text.NativeRendering
                            horizontalAlignment: Text.AlignHCenter
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.formatDateTime(clockTimer.now, "yy")
                            color: "#c0caf5"
                            font.family: "Cozette"
                            font.pixelSize: 9
                            renderType: Text.NativeRendering
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    Timer {
                        id: clockTimer
                        property var now: new Date()
                        interval: 1000
                        running: true
                        repeat: true
                        onTriggered: now = new Date()
                    }
                }

                Item { Layout.fillHeight: true }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 5
                    height: 5
                    color: "#7aa2f7"
                    antialiasing: false
                }

                Item { Layout.fillHeight: true }

                ColumnLayout {
                    id: mediaCluster
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 15
                        height: 15
                        color: "transparent"
                        border.color: "#414868"
                        border.width: 1
                        antialiasing: false
                    }

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredHeight: 8
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: console.log("launcher trigger clicked")
            }
        }

        BarDivider { Layout.alignment: Qt.AlignHCenter; barWidth: 32 }

    // --- System tray ---
        SystemTray {
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
