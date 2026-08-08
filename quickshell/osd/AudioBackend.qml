pragma Singleton
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

QtObject {
    id: root
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio.muted ?? false
    readonly property real volume: sink?.audio.volume ?? 0.0

    property PwObjectTracker tracker: PwObjectTracker {
        objects: [root.sink]
    }

    function setVolume(vol) {
        if (!sink?.ready)
            return;
        vol = Math.max(0, Math.min(1, vol));
        sink.audio.muted = false;
        sink.audio.volume = vol;
    }

    function toggleMute() {
        if (!sink?.ready)
            return;
        sink.audio.muted = !sink.audio.muted;
    }
}
