import Quickshell
import QtQuick
import QtQuick.Layouts
import "../bar"
import "../common"

Sheet {
    id: root
    property int stripWidth: 6
    shown: RightPanel.shown
    title: "Sound & light"
    subtitle: "Small adjustments, within reach."
    preferredWidth: 360; preferredHeight: 350
    onDismiss: RightPanel.shown = false
    onShownChanged: if (shown) BrightnessBackend.refresh()
    RowLayout {
        Layout.fillWidth: true
        PixelText { text: "Volume"; Layout.fillWidth: true }
        PixelText { text: AudioBackend.muted ? "Muted" : Math.round(AudioBackend.volume * 100) + "%"; color: Colors.accent }
    }
    PixelSlider { Layout.fillWidth: true; from: 0; to: 1; value: AudioBackend.volume; enabled: AudioBackend.sink?.ready ?? false; onMoved: AudioBackend.setVolume(value) }
    PixelButton { text: AudioBackend.muted ? "Unmute" : "Mute"; enabled: AudioBackend.sink?.ready ?? false; onClicked: AudioBackend.toggleMute() }
    PixelButton { text: "Audio devices…"; onClicked: Quickshell.execDetached(["pavucontrol"]) }
    PixelText { Layout.fillWidth: true; text: AudioBackend.sink?.description || "No audio output"; color: Colors.textOnSurfaceVariant }
    RowLayout {
        Layout.fillWidth: true
        PixelText { text: "Brightness"; Layout.fillWidth: true }
        PixelText { text: Math.round(BrightnessBackend.percent * 100) + "%"; color: Colors.accent }
    }
    PixelSlider { Layout.fillWidth: true; from: .02; to: 1; value: BrightnessBackend.percent; enabled: BrightnessBackend.available; onMoved: BrightnessBackend.setBrightness(value) }
    PixelText { text: BrightnessBackend.lastError; visible: text.length > 0; Layout.fillWidth: true; wrapMode: Text.Wrap; elide: Text.ElideNone; color: Colors.textOnSurfaceVariant }
}
