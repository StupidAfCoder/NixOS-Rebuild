import QtQuick
import Quickshell.Services.Mpris
import "."
import "../common"

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
                color: Colors.accent
                font.family: "Cozette"
                font.pixelSize: 9
                y: (rotWrap.height - height) / 2

                SequentialAnimation {
                    running: marqueeBox.overflowing && widget.active && widget.visible && !Settings.reducedMotion
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
                    color: widget.playing ? Colors.accent : Colors.outline
                    height: 4
                    anchors.bottom: parent.bottom

                    SequentialAnimation on height {
                        running: widget.playing && widget.visible && !Settings.reducedMotion
                        loops: Animation.Infinite
                        NumberAnimation { to: 4 + ((index * 2) % 7); duration: 260 + index * 70 }
                        NumberAnimation { to: 3; duration: 260 + index * 70 }
                    }
                }
            }
        }
    }

}
