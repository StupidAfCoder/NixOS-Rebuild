pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Hyprland
import "../common"
import "../bar"
import "../wallpaper"
import "../wellbeing"

Sheet {
    id: root
    shown: SettingsPanel.shown
    title: picking ? "Choose " + (pickKey === "wallpaperDir" ? "folder" : "file") : "Your corner"
    subtitle: Settings.error ? "Changes could not be saved" : Settings.saving ? "Saving…" : Settings.previewMode ? "Preview settings" : ""
    edge: "right"
    preferredWidth: 460
    preferredHeight: parent.height
    onDismiss: { if (picking) closePicker(); else SettingsPanel.hide(); }
    function closePicker() { picking = false; resetScroll(); forceActiveFocus(); }
    property bool picking: false
    property string pickKey: ""
    function pick(key, value, directory, filters) { pickKey = key; picking = true; pathPicker.start(value, directory, filters); resetScroll(); }
    property string tab: SettingsPanel.currentTab
    onTabChanged: if (shown) SettingsPanel.currentTab = tab
    property bool editingLayout: false
    property bool clearConfirm: false
    property bool resetConfirm: false
    onShownChanged: if (!shown) { clearConfirm = false; resetConfirm = false; picking = false; }

    PathPicker {
        id: pathPicker; visible: root.picking; Layout.fillWidth: true
        onChosen: path => { const patch = {}; patch[root.pickKey] = path; Settings.patch(patch); root.closePicker(); }
        onCancelled: { root.closePicker(); }
    }
    PixelText { text: Settings.error; visible: text.length > 0; color: Colors.error; Layout.fillWidth: true; wrapMode: Text.Wrap; elide: Text.ElideNone }
    Rectangle {
        Layout.fillWidth: true
        visible: !root.picking
        implicitHeight: identity.implicitHeight + 32
        color: Colors.surfaceContainer
        border.width: 0
        Rectangle { width: 3; height: parent.height; color: Colors.accent }
        RowLayout {
            id: identity
            x: 16; y: 16; width: parent.width - 32; spacing: 16
            ProfileAvatar { Layout.preferredWidth: 56; Layout.preferredHeight: 56 }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 5
                PixelText { text: Settings.displayName; Layout.fillWidth: true; font.family: "Pixel Operator"; font.pixelSize: 24 }
                PixelText { text: Settings.bio; Layout.fillWidth: true; color: Colors.textOnSurfaceVariant; wrapMode: Text.Wrap; elide: Text.ElideNone }
            }
        }
    }
    Flow {
        visible: !root.picking
        Layout.fillWidth: true; spacing: 6
        Repeater {
            model: [{id:"Profile",label:"Profile"},{id:"Bar",label:"Bar"},{id:"Appearance",label:"Look"},{id:"Audio",label:"Audio"},{id:"Privacy",label:"Data"}]
            TabButton {
                required property var modelData
                text: modelData.label
                selected: root.tab === modelData.id
                font.family: "Silkscreen"; font.pixelSize: 10
                onClicked: root.tab = modelData.id
            }
        }
    }
    ColumnLayout {
        visible: !root.picking && root.tab === "Profile"; Layout.fillWidth: true; spacing: 16
        PixelGroup {
            title: "Identity"; detail: "01"; iconName: "user.svg"; Layout.fillWidth: true
            PixelText { text: "Display name" }
            PixelField { Layout.fillWidth: true; text: Settings.displayName; onEditingFinished: Settings.patch({displayName: text}) }
            PixelText { text: "A short note" }
            PixelField { Layout.fillWidth: true; text: Settings.bio; onEditingFinished: Settings.patch({bio: text}) }
            PixelText { text: "Avatar / stays local" }
            MenuRow { Layout.fillWidth: true; label: Settings.avatarPath || "Choose a portrait…"; iconName: "folder.svg"; onClicked: root.pick("avatarPath", Settings.avatarPath, false, ["*.png", "*.jpg", "*.jpeg", "*.webp"]) }
            PixelButton { text: "Use initials"; visible: !!Settings.avatarPath; onClicked: Settings.patch({avatarPath: ""}) }
        }
        PixelGroup {
            title: "Your collection"; detail: "02"; iconName: "folder.svg"; Layout.fillWidth: true
            PixelText { text: "Power drawer video / local file" }
            MenuRow { Layout.fillWidth: true; label: Settings.videoPath; iconName: "folder.svg"; onClicked: root.pick("videoPath", Settings.videoPath, false, ["*.mp4", "*.mkv", "*.webm", "*.mov"]) }
            PixelText { text: "Wallpaper directory" }
            MenuRow { Layout.fillWidth: true; label: Settings.wallpaperDir; iconName: "folder.svg"; onClicked: root.pick("wallpaperDir", Settings.wallpaperDir, true, ["*"]) }
        }
    }
    ColumnLayout {
        visible: !root.picking && root.tab === "Bar"; Layout.fillWidth: true; spacing: 16
        PixelGroup {
            title: "Rail"; iconName: "app-windows.svg"; Layout.fillWidth: true
            RowLayout {
                Repeater {
                    model: ["left", "right", "top", "bottom"]
                    TabButton {
                        required property string modelData
                        text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                        selected: Settings.barEdge === modelData
                        onClicked: Settings.patch({barEdge: modelData})
                    }
                }
            }
            PixelText { text: "Opacity / " + Math.round(Settings.barOpacity * 100) + "%" }
            PixelSlider { Layout.fillWidth: true; from: .35; to: 1; stepSize: .01; value: Settings.barOpacity; onMoved: Settings.patch({barOpacity: value}) }
            PreferenceRow { Layout.fillWidth: true; label: "Background blur"; description: "Softens the desktop behind the translucent rail."; selected: Settings.barBlur; onToggled: Settings.patch({barBlur: !Settings.barBlur}) }
            PixelText {
                Layout.fillWidth: true; wrapMode: Text.Wrap; elide: Text.ElideNone; color: Colors.warning
                visible: Settings.barBlur && (Settings.barOpacity >= 1 || (Settings.previewMode && !Settings.previewBlurConfigured))
                text: [Settings.previewMode && !Settings.previewBlurConfigured ? "Preview needs --preview-blur or an already installed compositor rule." : "",
                       Settings.barOpacity >= 1 ? "Opacity is 100%. Lower it to see the blur." : ""].filter(s => s.length > 0).join("\n")
            }
            PreferenceRow { Layout.fillWidth: true; label: "Workspace manager button"; description: "When hidden, hover the last gem and confirm, search Library, or use Super+Ctrl+E."; selected: Settings.workspaceManagerButton; onToggled: Settings.patch({workspaceManagerButton: !Settings.workspaceManagerButton}) }
            PreferenceRow { Layout.fillWidth: true; label: "Window previews"; description: "Live and local, only while Workspaces is open. Nothing is saved."; selected: Settings.workspacePreviews; onToggled: Settings.patch({workspacePreviews: !Settings.workspacePreviews}) }
        }
        PixelGroup {
            title: "Modules"; iconName: "settings-2.svg"; Layout.fillWidth: true
            RowLayout {
                TabButton { text: "Modules"; selected: !root.editingLayout; onClicked: root.editingLayout = false }
                TabButton { text: "Placement"; selected: root.editingLayout; onClicked: root.editingLayout = true }
            }
            Repeater {
                model: root.editingLayout ? [] : Settings.moduleCatalog
                ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true; spacing: 12
                    PreferenceRow {
                        Layout.fillWidth: true
                        label: modelData.label; description: modelData.description; iconName: modelData.icon
                        selected: Settings.moduleEnabled(modelData.key)
                        onToggled: Settings.setModule(modelData.key, !Settings.moduleEnabled(modelData.key))
                    }
                    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Colors.outlineVariant }
                }
            }
            Repeater {
                model: root.editingLayout ? ["top", "middle", "bottom"] : []
                ColumnLayout {
                    id: zoneGroup
                    required property string modelData
                    Layout.fillWidth: true; spacing: 6
                    PixelText { text: zoneGroup.modelData === "middle" ? "Center" : zoneGroup.modelData === "top" ? (Settings.horizontalBar ? "Start" : "Top") : (Settings.horizontalBar ? "End" : "Bottom"); color: Colors.accent; font.family: "Silkscreen"; font.pixelSize: 10 }
                    Repeater {
                        model: Settings.barLayout[zoneGroup.modelData]
                        RowLayout {
                            id: moduleRow
                            required property string modelData
                            required property int index
                            Layout.fillWidth: true; spacing: 4
                            PixelText { Layout.fillWidth: true; text: Settings.moduleCatalog.find(m => m.key === moduleRow.modelData)?.label || moduleRow.modelData; opacity: Settings.moduleEnabled(moduleRow.modelData) ? 1 : .5 }
                            IconButton { iconName: Settings.horizontalBar ? "chevron-left.svg" : "chevron-up.svg"; hint: "Move " + moduleRow.modelData + " up"; enabled: moduleRow.index > 0; onClicked: Settings.relocateModule(moduleRow.modelData, zoneGroup.modelData, -1) }
                            IconButton { iconName: Settings.horizontalBar ? "chevron-right.svg" : "chevron-down.svg"; hint: "Move " + moduleRow.modelData + " down"; enabled: moduleRow.index < Settings.barLayout[zoneGroup.modelData].length - 1; onClicked: Settings.relocateModule(moduleRow.modelData, zoneGroup.modelData, 1) }
                            PixelButton { text: zoneGroup.modelData === "top" ? "To center" : zoneGroup.modelData === "middle" ? (Settings.horizontalBar ? "To end" : "To bottom") : (Settings.horizontalBar ? "To start" : "To top"); implicitWidth: 88; onClicked: Settings.relocateModule(moduleRow.modelData, zoneGroup.modelData === "top" ? "middle" : zoneGroup.modelData === "middle" ? "bottom" : "top", 0) }
                        }
                    }
                }
            }
            PixelButton { visible: root.editingLayout; text: "Reset placement"; onClicked: Settings.resetLayout() }
            PreferenceRow { Layout.fillWidth: true; label: "Show date"; description: "Wallpaper-colored day and month beside the clock."; selected: Settings.clockShowDate; onToggled: Settings.patch({clockShowDate: !Settings.clockShowDate}) }
        }
        PixelGroup {
            title: "Size"; iconName: "app-windows.svg"; Layout.fillWidth: true
            PixelText { text: "Workspace indicators / " + Settings.workspaceCount }
            PixelSlider { Layout.fillWidth: true; from: 1; to: 10; stepSize: 1; value: Settings.workspaceCount; onMoved: Settings.patch({workspaceCount: value}) }
            PixelText { text: "Rail width / " + Settings.barWidth + "px" }
            PixelSlider { Layout.fillWidth: true; from: 36; to: 64; stepSize: 2; value: Settings.barWidth; onMoved: Settings.patch({barWidth: value}) }
            PixelButton {
                Layout.fillWidth: true
                text: root.resetConfirm ? "Confirm restore all modules" : "Restore module defaults…"
                onClicked: {
                    if (root.resetConfirm) {
                        const defaults = {}; Settings.moduleCatalog.forEach(m => defaults[m.key] = m.key !== "system" && m.key !== "settings");
                        Settings.patch({barModules: defaults, workspaceCount: 5}); root.resetConfirm = false;
                    } else root.resetConfirm = true;
                }
            }
            PixelButton { visible: root.resetConfirm; text: "Cancel"; onClicked: root.resetConfirm = false }
        }
    }
    ColumnLayout {
        visible: !root.picking && root.tab === "Appearance"; Layout.fillWidth: true; spacing: 16
        PixelGroup {
            title: "App library"; iconName: "app-windows.svg"; Layout.fillWidth: true
            PixelText { text: "Open from"; color: Colors.textOnSurfaceVariant }
            RowLayout {
                Repeater {
                    model: [{key:"top",label:"Top"},{key:"bottom",label:"Bottom"},{key:"center",label:"Center"}]
                    TabButton {
                        required property var modelData
                        text: modelData.label
                        selected: Settings.launcherEdge === modelData.key
                        onClicked: Settings.patch({launcherEdge: modelData.key})
                    }
                }
            }
        }
        PixelGroup {
            title: "Edges & type"; iconName: "brush.svg"; Layout.fillWidth: true
            PreferenceRow { Layout.fillWidth: true; label: "Quick wallpaper edge"; description: "Click the middle of the right edge to browse wallpapers."; selected: Settings.quickWallpaperEdgeEnabled; onToggled: Settings.patch({quickWallpaperEdgeEnabled: !Settings.quickWallpaperEdgeEnabled}) }
            PixelText { text: "Frame / " + Settings.frameWidth + "px" }
            PixelSlider { Layout.fillWidth: true; from: 4; to: 10; stepSize: 1; value: Settings.frameWidth; onMoved: Settings.patch({frameWidth: value}) }
            PixelText { text: "Body text / " + Settings.bodySize + "px" }
            PixelSlider { Layout.fillWidth: true; from: 12; to: 18; stepSize: 1; value: Settings.bodySize; onMoved: Settings.patch({bodySize: value}) }
            PreferenceRow { Layout.fillWidth: true; label: "High contrast"; description: "Applied with the next wallpaper palette."; iconName: "brush.svg"; selected: Settings.contrast >= .5; onToggled: Settings.patch({contrast: Settings.contrast >= .5 ? 0 : 1}) }
            PixelButton { Layout.fillWidth: true; text: "Wallpaper, tone & palette…"; primary: true; onClicked: { SettingsPanel.hide(); WallpaperLauncher.toggle(); } }
        }
        PixelGroup {
            title: "Quiet motion"; iconName: "clock.svg"; Layout.fillWidth: true
            PixelText { text: "Transition time / " + (Settings.values.motionMs || 180) + "ms" }
            PixelSlider { Layout.fillWidth: true; from: 80; to: 350; stepSize: 10; value: Settings.values.motionMs || 180; enabled: !Settings.reducedMotion; onMoved: Settings.patch({motionMs: value}) }
            PreferenceRow { Layout.fillWidth: true; label: "Reduced motion"; description: "Instant drawers; pauses decorative motion and video."; iconName: "clock.svg"; selected: Settings.reducedMotion; onToggled: Settings.patch({reducedMotion: !Settings.reducedMotion}) }
        }
    }
    PixelGroup {
        visible: !root.picking && root.tab === "Audio"; Layout.fillWidth: true
        title: "Workspace audio"; iconName: "volume-2.svg"
        PreferenceRow { Layout.fillWidth: true; label: "Enable workspace muting"; description: "Opt in before choosing workspaces below."; iconName: "volume-2.svg"; selected: Settings.workspaceAudioEnabled; onToggled: Settings.patch({workspaceAudioEnabled: !Settings.workspaceAudioEnabled}) }
        Flow {
            Layout.fillWidth: true; spacing: 6
            Repeater {
                model: Hyprland.workspaces.values.filter(w => w.id > 0)
                PixelButton {
                    required property var modelData
                    text: "Workspace " + modelData.id + (Settings.mutedWorkspaces.indexOf(modelData.id) >= 0 ? " / muted" : "")
                    checked: Settings.mutedWorkspaces.indexOf(modelData.id) >= 0
                    enabled: Settings.workspaceAudioEnabled && !stateAction.running
                    onClicked: { stateAction.command = ["python3", Settings.repo + "scripts/shell-state.py", "toggle-workspace", String(modelData.id)]; stateAction.running = true; }
                }
            }
        }
        PixelText { text: Usage.audioStatus; Layout.fillWidth: true; wrapMode: Text.Wrap; elide: Text.ElideNone; color: Colors.textOnSurfaceVariant }
        PixelText { text: "Shared browser processes, remote and unidentified streams are skipped. Only mutes owned by this feature are restored; your existing mutes stay untouched."; Layout.fillWidth: true; wrapMode: Text.Wrap; elide: Text.ElideNone; color: Colors.textOnSurfaceVariant }
    }
    PixelGroup {
        visible: !root.picking && root.tab === "Privacy"; Layout.fillWidth: true
        title: "Time, kept locally"; iconName: "chart.svg"
        PreferenceRow { Layout.fillWidth: true; label: "Focused-app history"; description: "App classes and focused time. No titles, URLs or keystrokes."; iconName: "chart.svg"; selected: Settings.trackingEnabled; onToggled: Settings.patch({trackingEnabled: !Settings.trackingEnabled}) }
        PixelText { text: "Keep history / " + (Settings.values.retentionDays || 30) + " days" }
        PixelSlider { Layout.fillWidth: true; from: 1; to: 90; stepSize: 1; value: Settings.values.retentionDays || 30; onMoved: Settings.patch({retentionDays: value}) }
        PixelText { text: "Daily reference goal / " + Settings.dailyGoalMinutes + " minutes" }
        PixelSlider { Layout.fillWidth: true; from: 15; to: 1440; stepSize: 15; value: Settings.dailyGoalMinutes; onMoved: Settings.patch({dailyGoalMinutes: value}) }
        PixelText { text: "Calendar intensity uses ¼, ½ and 1× this goal, consistently across months. Idle detection depends on the installed Hypridle integration."; Layout.fillWidth: true; wrapMode: Text.Wrap; elide: Text.ElideNone; color: Colors.textOnSurfaceVariant }
        PixelButton { text: "Open Your day"; onClicked: { SettingsPanel.hide(); WellbeingPanel.toggle(); } }
        PixelButton { Layout.fillWidth: true; text: root.clearConfirm ? "Confirm delete local history" : "Clear local history…"; danger: root.clearConfirm; enabled: !stateAction.running; onClicked: { if (root.clearConfirm) { stateAction.command = ["python3", Settings.repo + "scripts/shell-state.py", "clear-history"]; stateAction.running = true; root.clearConfirm = false; } else root.clearConfirm = true; } }
        PixelButton { visible: root.clearConfirm; text: "Cancel"; onClicked: root.clearConfirm = false }
    }
    Process { id: stateAction; stderr: StdioCollector { onStreamFinished: { if (text.trim()) Settings.error = text.trim(); } } }
}
