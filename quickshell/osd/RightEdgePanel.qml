import QtQuick
import "../bar"

Item {
    id: root
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.right: parent.right

    property int stripWidth: 4       // pass manager.borderThickness in from ShellFrame
    readonly property int panelWidth: 96
    readonly property int panelHeight: 220
    readonly property int hoverBandHeight: panelHeight + 40   // generous target around center

    property alias hoverStripItem: hoverStrip
    property alias panelBezelItem: panelBezel

    Connections {
        target: RightPanel
        function onShownChanged() {
            if (RightPanel.shown)
                BrightnessBackend.refresh();
        }
    }

    // hover-in strip — centered band only, not the full border
    Item {
        id: hoverStrip
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: root.stripWidth
        height: root.hoverBandHeight

        HoverHandler {
            onHoveredChanged: RightPanel.hoverZone = hovered
        }
    }

    Rectangle {
        id: panelBezel
        anchors.right: hoverStrip.left
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter

        width: RightPanel.shown ? root.panelWidth : 0
        height: root.panelHeight
        clip: true
        color: Colors.shadow
        antialiasing: false

        Behavior on width {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        opacity: RightPanel.shown ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }
        }

        HoverHandler {
            onHoveredChanged: RightPanel.hoverPanel = hovered
        }

        Repeater {
            model: RightPanel.shown ? [
                {
                    x: 3,
                    y: 3
                },
                {
                    x: panelBezel.width - 5,
                    y: 3
                },
                {
                    x: 3,
                    y: panelBezel.height - 5
                },
                {
                    x: panelBezel.width - 5,
                    y: panelBezel.height - 5
                }
            ] : []
            delegate: Rectangle {
                x: modelData.x
                y: modelData.y
                width: 2
                height: 2
                color: Colors.outline
                antialiasing: false
            }
        }

        Rectangle {
            id: panelBox
            anchors.centerIn: parent
            width: Math.max(0, panelBezel.width - 12)
            height: Math.max(0, panelBezel.height - 12)
            color: Colors.background
            border.color: Colors.outlineVariant
            border.width: 1
            antialiasing: false

            Row {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 14

                // ---- volume slider ----
                Column {
                    width: 30
                    spacing: 6

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: AudioBackend.muted ? "MUTE" : Math.round(AudioBackend.volume * 100) + "%"
                        color: AudioBackend.muted ? Colors.error : Colors.textOnBackground
                        font.family: "Cozette"
                        font.pixelSize: 8
                    }

                    Rectangle {
                        id: volTrack
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 16
                        height: Math.max(0, panelBox.height - 58)
                        color: Colors.surfaceContainer
                        border.color: Colors.outlineVariant
                        border.width: 1
                        antialiasing: false

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: parent.height * (AudioBackend.muted ? 0 : AudioBackend.volume)
                            color: Colors.accent
                            antialiasing: false
                            Behavior on height {
                                NumberAnimation {
                                    duration: 90
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            preventStealing: true
                            function apply(my) {
                                const pct = 1 - Math.max(0, Math.min(1, my / height));
                                AudioBackend.setVolume(pct);
                            }
                            onPressed: mouse => apply(mouse.y)
                            onPositionChanged: mouse => {
                                if (pressed)
                                    apply(mouse.y);
                            }
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "VOL"
                        color: Colors.mutedOnBackground
                        font.family: "Cozette"
                        font.pixelSize: 7
                    }

                    MouseArea {
                        width: 30
                        height: 12
                        anchors.horizontalCenter: parent.horizontalCenter
                        onClicked: AudioBackend.toggleMute()
                        Text {
                            anchors.centerIn: parent
                            text: AudioBackend.muted ? "UNMUTE" : "MUTE"
                            color: Colors.mutedOnBackground
                            font.family: "Cozette"
                            font.pixelSize: 6
                        }
                    }
                }

                // ---- brightness slider ----
                Column {
                    width: 30
                    spacing: 6

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Math.round(BrightnessBackend.percent * 100) + "%"
                        color: Colors.textOnBackground
                        font.family: "Cozette"
                        font.pixelSize: 8
                    }

                    Rectangle {
                        id: briTrack
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 16
                        height: Math.max(0, panelBox.height - 58)
                        color: Colors.surfaceContainer
                        border.color: Colors.outlineVariant
                        border.width: 1
                        antialiasing: false

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: parent.height * BrightnessBackend.percent
                            color: Colors.accent
                            antialiasing: false
                            Behavior on height {
                                NumberAnimation {
                                    duration: 90
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            preventStealing: true
                            function apply(my) {
                                const pct = 1 - Math.max(0, Math.min(1, my / height));
                                BrightnessBackend.setBrightness(pct);
                            }
                            onPressed: mouse => apply(mouse.y)
                            onPositionChanged: mouse => {
                                if (pressed)
                                    apply(mouse.y);
                            }
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "BRI"
                        color: Colors.mutedOnBackground
                        font.family: "Cozette"
                        font.pixelSize: 7
                    }
                }
            }
        }
    }
}
