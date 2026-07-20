import QtQuick
import Quickshell.Services.Mpris
import "."

Item {
    id: widget
    width: 20

    readonly property var player: MprisActive.player
    readonly property bool active: MprisActive.hasPlayer && widget.player !== null && widget.player !== undefined
    readonly property bool playing: widget.active ? (widget.player.playbackState === MprisPlaybackState.Playing) : false

    // --- Track text: TOP, static unless it doesn't fit ---
    Item {
        id: marqueeBox
        anchors.top: parent.top
        anchors.bottom: statusRow.top
        anchors.bottomMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        width: 16
        clip: true

        readonly property string label: widget.active
            ? (widget.player.trackTitle || "Unknown Title") + "  —  " + (widget.player.trackArtist || "Unknown Artist")
            : ""

        readonly property bool overflowing: rotatedText.implicitWidth > marqueeBox.height

        Item {
            id: rotWrap
            width: marqueeBox.height
            height: marqueeBox.width
            anchors.centerIn: parent
            rotation: -90

            Text {
                id: rotatedText
                text: marqueeBox.label
                color: "#7aa2f7"
                font.family: "Cozette"
                font.pixelSize: 9
                y: (rotWrap.height - height) / 2

                SequentialAnimation {
                    running: marqueeBox.overflowing && widget.active
                    loops: Animation.Infinite

                    PauseAnimation { duration: 1200 }
                    NumberAnimation {
                        target: rotatedText; property: "x"
                        from: 0
                        to: -(rotatedText.implicitWidth - rotWrap.width)
                        duration: Math.max(900, rotatedText.implicitWidth * 22)
                        easing.type: Easing.Linear
                    }
                    PauseAnimation { duration: 700 }
                    // Fade out, snap back invisibly, fade in — no visible "reverse" motion
                    NumberAnimation { target: rotatedText; property: "opacity"; to: 0; duration: 120 }
                    PropertyAction { target: rotatedText; property: "x"; value: 0 }
                    NumberAnimation { target: rotatedText; property: "opacity"; to: 1; duration: 120 }
                }
            }
        }
    }

    // --- Equalizer bars: BOTTOM, rotated to run along the same axis as the text ---
    Item {
        id: statusRow
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: 12
        height: 12

        Row {
            id: eqRow
            anchors.centerIn: parent
            rotation: -90
            spacing: 3

            Repeater {
                model: 3
                delegate: Rectangle {
                    required property int index
                    width: 2
                    antialiasing: false
                    color: widget.playing ? "#7aa2f7" : "#565f89"
                    height: 4
                    anchors.bottom: parent.bottom

                    SequentialAnimation on height {
                        running: widget.playing
                        loops: Animation.Infinite
                        NumberAnimation { to: 4 + ((index * 2) % 7); duration: 260 + index * 70 }
                        NumberAnimation { to: 3; duration: 260 + index * 70 }
                    }
                }
            }
        }
    }

    MouseArea {
        id: mediaArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: MediaPanel.toggle()
    }

    Rectangle {
        id: hoverPreview
        visible: mediaArea.containsMouse && widget.active
        anchors.left: parent.right
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        width: 140
        height: previewCol.implicitHeight + 18
        color: "#1a1b26"
        border.color: "#414868"
        border.width: 1
        antialiasing: false
        z: 30

        Repeater {
            model: [
                { x: -1, y: -1, hFlip: false, vFlip: false },
                { x: hoverPreview.width - 9, y: -1, hFlip: true, vFlip: false },
                { x: -1, y: hoverPreview.height - 9, hFlip: false, vFlip: true },
                { x: hoverPreview.width - 9, y: hoverPreview.height - 9, hFlip: true, vFlip: true }
            ]
            delegate: Item {
                x: modelData.x; y: modelData.y
                width: 10; height: 10
                Rectangle {
                    width: 3; height: 10; antialiasing: false; color: "#565f89"
                    x: modelData.hFlip ? 7 : 0
                }
                Rectangle {
                    width: 10; height: 3; antialiasing: false; color: "#565f89"
                    y: modelData.vFlip ? 7 : 0
                }
            }
        }

        Column {
            id: previewCol
            anchors.centerIn: parent
            width: parent.width - 20
            spacing: 4

            Text {
                width: parent.width
                text: widget.active ? (widget.player.trackTitle || "Unknown Title") : ""
                color: "#c0caf5"; font.family: "Cozette"; font.pixelSize: 10; font.bold: true
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: widget.active ? (widget.player.trackArtist || "Unknown Artist") : ""
                color: "#a9b1d6"; font.family: "Cozette"; font.pixelSize: 9
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: widget.active ? (widget.playing ? "( Playing )" : "( Paused )") : ""
                color: "#565f89"; font.family: "Cozette"; font.pixelSize: 8
            }
        }
    }
}