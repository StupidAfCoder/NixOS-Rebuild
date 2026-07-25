import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "."

Item {
    id: content
    implicitWidth: 260
    implicitHeight: bezel.height
    width: implicitWidth
    height: implicitHeight
    anchors.horizontalCenter: parent.horizontalCenter
    visible: true
    z: 6

    readonly property var player: MprisActive.player
    readonly property bool hasPlayer: MprisActive.hasPlayer
    readonly property bool isPlaying: hasPlayer && player.playbackState === MprisPlaybackState.Playing

    y: MediaPanel.shown ? (parent.height - height + 2) : parent.height

    Behavior on y {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    // keeps position ticking while playing so the progress bar actually moves
    Timer {
        interval: 1000
        repeat: true
        running: content.isPlaying && MediaPanel.shown
        onTriggered: content.player.positionChanged()
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
                spacing: 8
                z: 4

                Text {
                    visible: !content.hasPlayer
                    text: "NO MEDIA PLAYING"
                    color: Colors.mutedOnBackground
                    font.family: "Cozette"
                    font.pixelSize: 9
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 10
                    Layout.bottomMargin: 10
                }

                RowLayout {
                    visible: content.hasPlayer && MprisActive.players.count > 1
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4
                    Repeater {
                        model: MprisActive.players.count
                        delegate: Rectangle {
                            required property int index
                            width: 6; height: 6
                            antialiasing: false
                            color: index === MprisActive.players.values.indexOf(content.player) ? Colors.accent : Colors.outlineVariant
                            MouseArea {
                                anchors.fill: parent
                                onClicked: MprisActive.selectPlayer(parent.index)
                            }
                        }
                    }
                }

                RowLayout {
                    visible: content.hasPlayer
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 56
                        Layout.preferredHeight: 56
                        color: Colors.surfaceContainerLow
                        border.color: Colors.outlineVariant
                        border.width: 1
                        antialiasing: false
                        clip: true

                        Image {
                            anchors.fill: parent
                            anchors.margins: 2
                            source: content.player?.trackArtUrl ? content.player.trackArtUrl : ""
                            fillMode: Image.PreserveAspectCrop
                            smooth: false
                            asynchronous: true
                            visible: source !== ""
                        }

                        Text {
                            visible: !content.hasPlayer || content.player.trackArtUrl === ""
                            anchors.centerIn: parent
                            text: "\u266b"
                            color: Colors.outlineVariant
                            font.pixelSize: 20
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: content.hasPlayer ? (content.player.trackTitle || "Unknown Title") : ""
                            color: Colors.textOnBackground
                            font.family: "Cozette"
                            font.pixelSize: 10
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: content.hasPlayer ? (content.player.trackArtist || "Unknown Artist") : ""
                            color: Colors.mutedOnBackground
                            font.family: "Cozette"
                            font.pixelSize: 9
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            visible: content.player?.trackAlbum !== ""
                            text: content.player?.trackAlbum ? content.player.trackAlbum : ""
                            color: Colors.mutedOnBackground
                            font.family: "Cozette"
                            font.pixelSize: 8
                            elide: Text.ElideRight
                        }
                    }
                }

                ColumnLayout {
                    visible: content.hasPlayer
                    Layout.fillWidth: true
                    spacing: 3

                    Item {
                        id: progressTrack
                        Layout.fillWidth: true
                        Layout.preferredHeight: 10

                        readonly property int segCount: 26
                        readonly property real pct: (content.player?.length > 0)
                            ? Math.min(1, content.player.position / content.player.length) : 0

                        Row {
                            anchors.fill: parent
                            spacing: 1
                            Repeater {
                                model: progressTrack.segCount
                                delegate: Rectangle {
                                    required property int index
                                    width: (progressTrack.width - (progressTrack.segCount - 1)) / progressTrack.segCount
                                    height: 10
                                    antialiasing: false
                                    color: (index / progressTrack.segCount) < progressTrack.pct ? Colors.accentSecondary : Colors.surfaceContainerHigh
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: content.player?.canSeek
                            onClicked: (mouse) => {
                                const frac = Math.min(1, Math.max(0, mouse.x / width))
                                content.player.position = frac * content.player.length
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: content.hasPlayer ? content.formatTime(content.player.position) : "0:00"
                            color: Colors.mutedOnBackground
                            font.family: "Cozette"
                            font.pixelSize: 8
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: content.hasPlayer ? content.formatTime(content.player.length) : "0:00"
                            color: Colors.mutedOnBackground
                            font.family: "Cozette"
                            font.pixelSize: 8
                        }
                    }
                }

                RowLayout {
                    visible: content.hasPlayer
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    spacing: 6

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        Layout.preferredWidth: 28; Layout.preferredHeight: 22
                        color: prevArea.containsMouse ? Colors.surfaceContainer : "transparent"
                        border.color: Colors.outlineVariant; border.width: 1
                        antialiasing: false
                        opacity: content.player?.canGoPrevious ? 1.0 : 0.35
                        Text { anchors.centerIn: parent; text: "|<"; color: Colors.textOnBackground; font.family: "Cozette"; font.pixelSize: 9 }
                        MouseArea {
                            id: prevArea
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: content.player?.canGoPrevious
                            cursorShape: Qt.PointingHandCursor
                            onClicked: content.player.previous()
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 32; Layout.preferredHeight: 22
                        color: playArea.containsMouse ? Colors.surfaceContainer : "transparent"
                        border.color: Colors.accent; border.width: 1
                        antialiasing: false
                        opacity: content.player?.canTogglePlaying ? 1.0 : 0.35
                        Text {
                            anchors.centerIn: parent
                            text: content.isPlaying ? "||" : ">"
                            color: Colors.accent
                            font.family: "Cozette"
                            font.pixelSize: 10
                            font.bold: true
                        }
                        MouseArea {
                            id: playArea
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: content.player?.canTogglePlaying
                            cursorShape: Qt.PointingHandCursor
                            onClicked: content.player.togglePlaying()
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 28; Layout.preferredHeight: 22
                        color: nextArea.containsMouse ? Colors.surfaceContainer : "transparent"
                        border.color: Colors.outlineVariant; border.width: 1
                        antialiasing: false
                        opacity: content.player?.canGoNext ? 1.0 : 0.35
                        Text { anchors.centerIn: parent; text: ">|"; color: Colors.textOnBackground; font.family: "Cozette"; font.pixelSize: 9 }
                        MouseArea {
                            id: nextArea
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: content.player?.canGoNext
                            cursorShape: Qt.PointingHandCursor
                            onClicked: content.player.next()
                        }
                    }

                    Item { Layout.fillWidth: true }
                }
            }
        }
    }

    function formatTime(seconds) {
        if (!seconds || seconds < 0) return "0:00"
        const m = Math.floor(seconds / 60)
        const s = Math.floor(seconds % 60)
        return m + ":" + (s < 10 ? "0" : "") + s
    }
}