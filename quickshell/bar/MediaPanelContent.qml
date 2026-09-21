import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../common"

Sheet {
    id: root
    shown: MediaPanel.shown
    title: "Now playing"
    subtitle: player ? player.identity : "No active player"
    preferredWidth: 550
    preferredHeight: 430
    onDismiss: MediaPanel.hide()
    readonly property var player: MprisActive.player
    function formatTime(seconds) { return Math.floor(Math.max(0, seconds) / 60) + ":" + String(Math.floor(Math.max(0, seconds) % 60)).padStart(2, "0"); }
    Timer { interval: 1000; running: root.shown && root.player && root.player.playbackState === MprisPlaybackState.Playing; repeat: true; onTriggered: root.player.positionChanged() }
    GridLayout {
        Layout.fillWidth: true; columns: root.width > 440 ? 2 : 1; columnSpacing: 20
        Rectangle {
            Layout.preferredWidth: root.width > 440 ? 160 : 240; Layout.preferredHeight: 160
            color: Colors.surfaceContainerHigh
            PixelText { anchors.centerIn: parent; text: "♫"; font.pixelSize: 40; color: Colors.accent }
            Image { anchors.fill: parent; source: root.player?.trackArtUrl || ""; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 400 }
        }
        ColumnLayout {
            Layout.fillWidth: true
            PixelText { Layout.fillWidth: true; text: root.player?.trackTitle || "Nothing playing"; font.pixelSize: 18; wrapMode: Text.Wrap; elide: Text.ElideNone }
            PixelText { Layout.fillWidth: true; text: root.player?.trackArtist || "Open your favorite music app"; color: Colors.textOnSurfaceVariant }
            PixelText { Layout.fillWidth: true; text: root.player?.trackAlbum || ""; color: Colors.textOnSurfaceVariant }
            RowLayout {
                PixelButton { text: "|<"; Accessible.name: "Previous"; enabled: root.player?.canGoPrevious ?? false; onClicked: root.player.previous() }
                PixelButton { text: root.player?.playbackState === MprisPlaybackState.Playing ? "Pause" : "Play"; primary: true; enabled: root.player?.canTogglePlaying ?? false; onClicked: root.player.togglePlaying() }
                PixelButton { text: ">|"; Accessible.name: "Next"; enabled: root.player?.canGoNext ?? false; onClicked: root.player.next() }
            }
        }
    }
    PixelSlider { Layout.fillWidth: true; from: 0; to: Math.max(1, root.player?.length || 0); value: root.player?.position || 0; enabled: (root.player?.canSeek ?? false) && (root.player?.length || 0) > 0; onMoved: root.player.position = value }
    PixelText { text: root.formatTime(root.player?.position || 0) + " / " + root.formatTime(root.player?.length || 0); color: Colors.textOnSurfaceVariant }
    Flow {
        Layout.fillWidth: true; spacing: 6
        PixelButton { text: "Auto"; checked: MprisActive.selectedIndex === -1; onClicked: MprisActive.selectPlayer(-1) }
        Repeater { model: MprisActive.players ? MprisActive.players.values : []; PixelButton { required property var modelData; required property int index; text: modelData.identity; checked: MprisActive.selectedIndex === index; onClicked: MprisActive.selectPlayer(index) } }
    }
}
