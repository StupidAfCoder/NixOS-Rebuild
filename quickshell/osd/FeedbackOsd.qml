import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../common"
import "../bar"

Scope {
    id: root
    property string label: ""
    property real value: 0
    property bool initialized: false
    function show(label, value) { if (!initialized) return; root.label = label; root.value = value; timeout.restart(); }
    Timer { interval: 1000; running: true; onTriggered: root.initialized = true }
    Timer { id: timeout; interval: 1300 }
    Connections {
        target: AudioBackend
        function onVolumeChanged() { root.show("Volume", AudioBackend.volume); }
        function onMutedChanged() { root.show(AudioBackend.muted ? "Muted" : "Volume", AudioBackend.muted ? 0 : AudioBackend.volume); }
    }
    Connections { target: BrightnessBackend; function onPercentChanged() { if (BrightnessBackend.available) root.show("Brightness", BrightnessBackend.percent); } }
    PanelWindow {
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) || Quickshell.screens[0]
        visible: timeout.running
        anchors.bottom: true
        margins.bottom: Settings.frameWidth + 30
        implicitWidth: 280; implicitHeight: 62
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        mask: Region {}
        Rectangle {
            anchors.fill: parent; color: Colors.surfaceContainerLow; border.color: Colors.outlineVariant
            PixelText { anchors.left: parent.left; anchors.top: parent.top; anchors.margins: 12; text: root.label }
            PixelText { anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 12; text: Math.round(root.value * 100) + "%"; color: Colors.accent }
            Rectangle { x: 12; y: 43; width: parent.width - 24; height: 4; color: Colors.surfaceContainerHigh
                Rectangle { height: 4; width: parent.width * Math.max(0, Math.min(1, root.value)); color: Colors.accent; Behavior on width { NumberAnimation { duration: Settings.motionMs / 2 } } }
            }
        }
    }
}
