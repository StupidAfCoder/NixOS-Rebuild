import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "."

Item {
    id: root
    property int barWidth: 52

    width: barWidth

    readonly property var wsIcons: [
        "circle.svg", "square.svg", "star.svg", "heart.svg", "zap.svg"
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 12
        anchors.bottomMargin: 12
        spacing: 10

        // --- NixOS logo / power button ---
        BarPill {
            Layout.alignment: Qt.AlignHCenter
            width: 40
            height: 40
            fillColor: "#1a1b26"
            cornerCut: 8
            stairSteps: 4
            showRivets: true
            rivetSize: 8
            showBrackets: true
            bracketWidthScale: 1.6
            bracketLengthScale: 2.0

            Image {
                anchors.centerIn: parent
                width: 24
                height: 24
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
            spacing: 6

            Repeater {
                model: 5

                BarPill {
                    id: wsPill
                    required property int index
                    property int wsId: index + 1
                    property var wsData: Hyprland.workspaces.values.find(w => w.id === wsId)
                    property bool isActive: Hyprland.focusedWorkspace?.id === wsId

                    width: 32
                    height: 32
                    cornerCut: 10
                    stairSteps: 3
                    fillColor: isActive ? "#7aa2f7" : (wsData ? "#414868" : "#1a1b26")

                    Image {
                        id: wsIconImg
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        source: "file:///home/swami/.local/share/pixelarticons/svg/" + root.wsIcons[wsPill.index]
                        smooth: false
                    }

                    ColorOverlay {
                        anchors.fill: wsIconImg
                        source: wsIconImg
                        color: wsPill.isActive ? "#1a1b26" : "#7982a9"
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

        // --- Middle zone: clock stays pinned top, dot now floats centered
        // in the flex gap (separated from the clock so it doesn't compete
        // visually with the rivet sitting right next to it), media at bottom. ---
        BarPill {
            id: middleZone
            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: true
            Layout.bottomMargin: 5
            width: 44
            cornerCut: 12
            stairSteps: 4
            showRivets: true
            rivetSize: 9
            showBrackets: true
            bracketWidthScale: 6.2
            bracketLengthScale: 1.4
            showChain: true
            chainLinkSize: 10
            chainRingThickness: 2.01

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 14
                anchors.bottomMargin: 12
                spacing: 0

                // --- Top region: separator + vertical clock only ---
                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 10

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredHeight: 4
                    }

                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 2

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.formatDateTime(clockTimer.now, "hh")
                            color: "#c0caf5"
                            font.family: "Pixel Operator"
                            font.pixelSize: 20
                            font.bold: true
                            renderType: Text.NativeRendering
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.formatDateTime(clockTimer.now, "mm")
                            color: "#c0caf5"
                            font.family: "Pixel Operator"
                            font.pixelSize: 20
                            font.bold: true
                            renderType: Text.NativeRendering
                            horizontalAlignment: Text.AlignHCenter
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
                }

                // --- Flexible gap split around a centered dot ---
                Item { Layout.fillHeight: true }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 8
                    height: 8
                    color: "#7aa2f7"
                    antialiasing: false
                }

                Item { Layout.fillHeight: true }

                // --- Bottom region: media placeholder ---
                ColumnLayout {
                    id: mediaCluster
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 20
                        height: 20
                        color: "transparent"
                        border.color: "#414868"
                        border.width: 2
                        antialiasing: false
                    }

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredHeight: 14
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: console.log("launcher trigger clicked")
            }
        }

        // --- System tray ---
        BarPill {
            Layout.alignment: Qt.AlignHCenter
            width: 44
            height: 170
            cornerCut: 0
            showRivets: true
            rivetSize: 11
            showBrackets: true
            bracketWidthScale: 5
            bracketLengthScale: 2.6
            showChain: true
            chainLinkSize: 12

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 12

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "N"
                    color: "#7982a9"
                    font.family: "Cozette"
                    font.pixelSize: 14
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "B"
                    color: "#7982a9"
                    font.family: "Cozette"
                    font.pixelSize: 14
                }
            }
        }
    }
}
