pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtMultimedia
import Quickshell
import Quickshell.Io
import "../common"

Sheet {
    id: root
    shown: PowerMenu.shown
    title: "Session"
    preferredWidth: 330
    preferredHeight: 560
    edge: "right"
    property string pending: ""
    property string actionMessage: ""
    property string clipError: ""
    function cancel() { if (pending) pending = ""; else PowerMenu.hide(); }
    function confirm(action) { pending = action; Qt.callLater(function() { cancelButton.forceActiveFocus(); }); }
    function execute(action) {
        if (Settings.previewMode) { pending = ""; actionMessage = "Preview only · " + action + " was not executed."; return; }
        PowerMenu.hide();
        if (action === "Lock") Quickshell.execDetached(["hyprlock"]);
        else if (action === "Sleep") Quickshell.execDetached(["systemctl", "suspend"]);
        else if (action === "Log out") Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.exit()"]);
        else if (action === "Restart") Quickshell.execDetached(["systemctl", "reboot"]);
        else if (action === "Shut down") Quickshell.execDetached(["systemctl", "poweroff"]);
    }
    onDismiss: cancel()
    onShownChanged: { pending = ""; actionMessage = ""; clipError = ""; }
    Rectangle {
        Layout.fillWidth: true; Layout.preferredHeight: 155
        color: Colors.background
        border.color: Colors.outlineVariant
        PixelText { anchors.centerIn: parent; text: root.clipError ? "Video unavailable" : Settings.reducedMotion ? "Motion paused" : "Session"; color: Colors.textOnSurfaceVariant }
        Loader {
            id: sessionClip
            anchors.fill: parent; anchors.margins: 6
            // No decoder, GPU surfaces or audio output survive a closed drawer.
            active: root.shown && !Settings.reducedMotion
            sourceComponent: Component {
                Item {
                    function reloadClip() { player.stop(); player.source = ""; player.source = Settings.fileUrl(Settings.videoPath); }
                    VideoOutput { id: output; anchors.fill: parent; fillMode: VideoOutput.PreserveAspectCrop }
                    MediaPlayer {
                        id: player
                        source: Settings.fileUrl(Settings.videoPath)
                        videoOutput: output
                        audioOutput: null
                        loops: MediaPlayer.Infinite
                        property bool initialized: false
                        Component.onCompleted: { initialized = true; play(); }
                        onSourceChanged: if (initialized && source.toString()) play()
                        onErrorOccurred: (error, errorString) => { root.clipError = errorString; }
                    }
                }
            }
        }
        FileView {
            path: Settings.videoPath; watchChanges: true; preload: false
            onFileChanged: if (sessionClip.item) sessionClip.item.reloadClip()
        }
    }
    ColumnLayout {
        visible: !root.pending; Layout.fillWidth: true; spacing: 6
        Repeater {
            model: [{name:"Lock",icon:"lock.svg"},{name:"Sleep",icon:"clock.svg"},{name:"Log out",icon:"app-windows.svg"},{name:"Restart",icon:"power.svg"},{name:"Shut down",icon:"power.svg"}]
            MenuRow {
                required property var modelData
                Layout.fillWidth: true; implicitHeight: 38; padding: 8
                label: modelData.name; iconName: modelData.icon; raised: true
                danger: modelData.name === "Shut down"
                onClicked: modelData.name === "Lock" || modelData.name === "Sleep" ? root.execute(modelData.name) : root.confirm(modelData.name)
            }
        }
    }
    ColumnLayout {
        visible: !!root.pending; Layout.fillWidth: true; spacing: 18
        PixelText { text: root.pending + "?"; font.family: "Silkscreen"; font.pixelSize: 14 }
        PixelText { text: "Save your progress before ending this session."; Layout.fillWidth: true; wrapMode: Text.Wrap }
        RowLayout {
            Layout.fillWidth: true
            PixelButton { id: cancelButton; text: "Keep playing"; Layout.fillWidth: true; onClicked: root.pending = "" }
            PixelButton { text: root.pending; danger: true; Layout.fillWidth: true; onClicked: root.execute(root.pending) }
        }
    }
    PixelText { text: root.actionMessage; visible: !!text; Layout.fillWidth: true; wrapMode: Text.Wrap; elide: Text.ElideNone; color: Colors.accent }
}
