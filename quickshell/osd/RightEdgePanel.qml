import Quickshell
import QtQuick
import QtQuick.Layouts
import "../bar"
import "../common"

Sheet {
    id: root
    shown: RightPanel.shown
    title: "Sound & light"
    preferredWidth: 310; preferredHeight: BrightnessBackend.available ? 330 : 240
    onDismiss: RightPanel.shown = false
    onShownChanged: if (shown) BrightnessBackend.refresh()
    RowLayout {
        Layout.fillWidth: true; spacing: 12
        IconButton { iconName: "volume-2.svg"; hint: AudioBackend.muted ? "Unmute" : "Mute"; checked: AudioBackend.muted; enabled: AudioBackend.sink?.ready ?? false; onClicked: AudioBackend.toggleMute() }
        PixelSlider { Layout.fillWidth: true; from: 0; to: 1; value: AudioBackend.volume; enabled: AudioBackend.sink?.ready ?? false; onMoved: AudioBackend.setVolume(value) }
        PixelText { text: AudioBackend.muted ? "Off" : Math.round(AudioBackend.volume * 100) + "%" }
    }
    MenuRow {
        Layout.fillWidth: true
        label: AudioBackend.sink?.description || "No audio output"
        detail: "Output devices"
        onClicked: Quickshell.execDetached(["pavucontrol"])
    }
    RowLayout {
        visible: BrightnessBackend.available; Layout.fillWidth: true; spacing: 12
        PixelText { text: "Light" }
        PixelSlider { Layout.fillWidth: true; from: .02; to: 1; value: BrightnessBackend.percent; onMoved: BrightnessBackend.setBrightness(value) }
        PixelText { text: Math.round(BrightnessBackend.percent * 100) + "%" }
    }
    PixelText { visible: !BrightnessBackend.available; text: "No adjustable display detected."; Layout.fillWidth: true; color: Colors.textOnSurfaceVariant }
}
