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
    title: pending ? pending + "?" : "Session"
    subtitle: pending ? "Save your work before continuing." : Settings.displayName
    preferredWidth: 380
    preferredHeight: 560
    edge: "right"
    property string pending: ""
    property string actionMessage: ""
    function cancel() { if (pending) pending = ""; else PowerMenu.hide(); }
    onDismiss: cancel()
    onShownChanged: {
        pending = "";
        actionMessage = "";
        if (shown && !Settings.reducedMotion) video.play(); else video.stop();
    }
    Connections {
        target: Settings
        function onReducedMotionChanged() { if (Settings.reducedMotion) video.pause(); else if (root.shown) video.play(); }
    }
    FileView {
        path: Settings.videoPath; watchChanges: true
        onFileChanged: { video.stop(); video.source = ""; video.source = Settings.fileUrl(Settings.videoPath); if (root.shown && !Settings.reducedMotion) video.play(); }
    }
    function execute(action) {
        if (Settings.previewMode) { pending = ""; actionMessage = "Preview only: " + action + " was not executed."; return; }
        PowerMenu.hide();
        if (action === "Lock") Quickshell.execDetached(["hyprlock"]);
        else if (action === "Sleep") Quickshell.execDetached(["systemctl", "suspend"]);
        else if (action === "Log out") Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.exit()"]);
        else if (action === "Restart") Quickshell.execDetached(["systemctl", "reboot"]);
        else if (action === "Shut down") Quickshell.execDetached(["systemctl", "poweroff"]);
    }
    PixelText { text: root.actionMessage; visible: text.length > 0; Layout.fillWidth: true; wrapMode: Text.Wrap; color: Colors.accent }
    function confirm(action) { pending = action; Qt.callLater(function() { cancelButton.forceActiveFocus(); }); }
    Rectangle {
        Layout.fillWidth: true; Layout.preferredHeight: 170
        color: Colors.background; border.color: Colors.outlineVariant
        PixelText { anchors.centerIn: parent; text: "A moment of quiet."; color: Colors.textOnSurfaceVariant }
        Video {
            id: video
            anchors.fill: parent; anchors.margins: 2
            source: Settings.fileUrl(Settings.videoPath)
            fillMode: VideoOutput.PreserveAspectCrop
            smooth: false; muted: true; loops: MediaPlayer.Infinite
            onSourceChanged: if (root.shown && !Settings.reducedMotion) play()
        }
        Rectangle { anchors.left: parent.left; anchors.top: parent.top; width: 16; height: 2; color: Colors.accent }
        Rectangle { anchors.right: parent.right; anchors.bottom: parent.bottom; width: 16; height: 2; color: Colors.accent }
    }
    RowLayout {
        visible: !root.pending; Layout.fillWidth: true
        ProfileAvatar { Layout.preferredWidth: 42; Layout.preferredHeight: 42 }
        ColumnLayout { Layout.fillWidth: true; PixelText { text: Settings.displayName; Layout.fillWidth: true } PixelText { text: Settings.bio; Layout.fillWidth: true; color: Colors.textOnSurfaceVariant } }
    }
    GridLayout {
        visible: !root.pending; Layout.fillWidth: true; columns: 2; rowSpacing: 8; columnSpacing: 8
        Repeater {
            model: ["Lock", "Sleep", "Log out", "Restart"]
            PixelButton { required property string modelData; Layout.fillWidth: true; text: modelData; onClicked: modelData === "Lock" || modelData === "Sleep" ? root.execute(modelData) : root.confirm(modelData) }
        }
    }
    PixelButton { visible: !root.pending; Layout.fillWidth: true; text: "Shut down…"; danger: true; onClicked: root.confirm("Shut down") }
    PixelText { visible: !!root.pending; Layout.fillWidth: true; text: "Your session will end. Unsaved work may be lost."; wrapMode: Text.Wrap; elide: Text.ElideNone }
    RowLayout {
        visible: !!root.pending; Layout.fillWidth: true
        PixelButton { id: cancelButton; text: "Cancel"; Layout.fillWidth: true; onClicked: root.pending = "" }
        PixelButton { text: root.pending; danger: true; Layout.fillWidth: true; onClicked: root.execute(root.pending) }
    }
}
