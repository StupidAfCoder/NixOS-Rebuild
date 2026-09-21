pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../common"
import "../wallpaper"
import "../launcher"
import "../settings"
import "../wellbeing"
import "../osd"
import "../sysstats"

Item {
    id: root
    property int barWidth: Settings.barWidth
    width: barWidth
    readonly property string defaultWsIcon: "app-windows.svg"
    readonly property var classIconRules: [
        {
            match: ["firefox", "librewolf", "zen", "chromium", "chrome", "brave"],
            icon: "globe.svg"
        },
        {
            match: ["kitty", "alacritty", "foot", "wezterm", "konsole", "xterm", "gnome-terminal"],
            icon: "terminal.svg"
        },
        {
            match: ["discord", "telegram", "slack", "whatsapp", "element", "signal"],
            icon: "message.svg"
        },
        {
            match: ["spotify", "mpv", "vlc", "rhythmbox"],
            icon: "music.svg"
        },
        {
            match: ["code", "codium", "jetbrains", "idea", "pycharm", "clion", "sublime", "neovide", "nvim" , "emacs"],
            icon: "braces.svg"
        },
        {
            match: ["thunar", "nautilus", "dolphin", "pcmanfm", "files"],
            icon: "folder.svg"
        },
        {
            match: ["steam"],
            icon: "gamepad.svg"
        },
        {
            match: ["obsidian", "notion"],
            icon: "notebook.svg"
        },
        {
            match: ["gimp", "inkscape", "krita", "aseprite"],
            icon: "brush.svg"
        }
    ]

    function iconForClass(cls) {
        if (!cls)
            return root.defaultWsIcon;
        const c = cls.toLowerCase();
        for (let i = 0; i < root.classIconRules.length; i++) {
            const rule = root.classIconRules[i];
            for (let j = 0; j < rule.match.length; j++) {
                if (c.indexOf(rule.match[j]) !== -1)
                    return rule.icon;
            }
        }
        return root.defaultWsIcon;
    }


    Timer {
        interval: 2000; repeat: true
        running: root.visible && Settings.moduleEnabled("workspaces")
        onTriggered: Hyprland.refreshToplevels()
    }
    Timer {
        id: clockTimer
        property date now: new Date()
        interval: 1000; running: Settings.moduleEnabled("clock"); repeat: true
        onTriggered: now = new Date()
    }
    Rectangle { anchors.fill: parent; color: Colors.background }
    // Scroll instead of overlapping when a short screen or a large tray runs out of space.
    Flickable {
        id: scroll
        anchors.fill: parent; anchors.bottomMargin: 46
        contentWidth: width
        contentHeight: Math.max(height, rail.implicitHeight + 24)
        clip: true; boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        ScrollBar.vertical: ScrollBar { width: 3; policy: scroll.contentHeight > scroll.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff }
        ColumnLayout {
            id: rail
            y: 12; width: parent.width
            height: Math.max(implicitHeight, scroll.height - 24)
            spacing: 10
            IconButton {
                visible: Settings.moduleEnabled("launcher")
                Layout.alignment: Qt.AlignHCenter
                hint: "Launch apps"
                iconName: "nixos.svg"
                onClicked: AppLauncher.toggle()
            }
            ColumnLayout {
                visible: Settings.moduleEnabled("workspaces")
                Layout.alignment: Qt.AlignHCenter; spacing: 4
                Repeater {
                    model: Settings.workspaceCount
                    PixelButton {
                        id: ws
                        required property int index
                        readonly property int wsId: index + 1
                        readonly property var dataForWorkspace: Hyprland.workspaces.values.find(w => w.id === wsId)
                        readonly property bool isActive: Hyprland.focusedWorkspace?.id === wsId
                        readonly property bool occupied: !!dataForWorkspace && dataForWorkspace.toplevels.values.length > 0
                        readonly property var topWindow: occupied ? (dataForWorkspace.toplevels.values.find(w => w.activated) || dataForWorkspace.toplevels.values[0]) : null
                        implicitWidth: 30; implicitHeight: 28; padding: 4
                        primary: isActive
                        Accessible.name: "Workspace " + wsId
                        contentItem: Item {
                            ColoredIcon { anchors.fill: parent; visible: ws.occupied || ws.isActive; iconName: root.iconForClass(ws.topWindow?.lastIpcObject?.class || ""); tint: ws.isActive ? Colors.textOnAccent : Colors.textOnBackground }
                            Repeater {
                                model: !ws.occupied && !ws.isActive ? [{x:2,y:2},{x:16,y:1},{x:6,y:14},{x:18,y:15},{x:10,y:7}] : []
                                Rectangle { required property var modelData; x: modelData.x; y: modelData.y; width: 2; height: 2; color: Colors.accent; opacity: .65 }
                            }
                        }
                        onClicked: Hyprland.dispatch('hl.dsp.focus({ workspace = "' + ws.wsId + '" })')
                        ToolTip.visible: hovered || activeFocus
                        ToolTip.text: Accessible.name
                    }
                }
            }
            PixelButton {
                visible: Settings.moduleEnabled("clock")
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 34; implicitHeight: root.height > 740 ? 82 : 52
                padding: 3
                Accessible.name: "Clock and Your day"
                contentItem: Column {
                    spacing: 4
                    PixelText { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: Qt.formatTime(clockTimer.now, "hh\nmm"); font.family: "Pixel Operator"; font.pixelSize: 16 }
                    PixelText { visible: root.height > 740; width: parent.width; horizontalAlignment: Text.AlignHCenter; text: Qt.formatDate(clockTimer.now, "dd\nMM"); color: Colors.textOnSurfaceVariant; font.pixelSize: 12 }
                }
                onClicked: WellbeingPanel.toggle()
            }
            Item { Layout.fillHeight: true; Layout.minimumHeight: 8 }
            PixelButton {
                visible: Settings.moduleEnabled("wizard")
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 36; implicitHeight: 36; padding: 6
                Accessible.name: "Wallpaper wizard"
                contentItem: ReactiveImage { path: Settings.cacheDir + "/wizard-idle.png"; fallbackSource: Qt.resolvedUrl("assets/wizard-template.png") }
                onClicked: WallpaperLauncher.toggle()
                ToolTip.visible: hovered || activeFocus
                ToolTip.text: "Choose wallpaper and palette"
            }
            MediaBarWidget {
                visible: Settings.moduleEnabled("media") && root.height > 920
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 24; Layout.preferredHeight: 150
            }
            IconButton {
                visible: Settings.moduleEnabled("media") && root.height <= 920
                Layout.alignment: Qt.AlignHCenter
                iconName: "music.svg"; hint: "Now playing"
                onClicked: MediaPanel.toggle()
            }
            Item { Layout.fillHeight: true; Layout.minimumHeight: 8 }
            IconButton { visible: Settings.moduleEnabled("audio"); Layout.alignment: Qt.AlignHCenter; iconName: "volume-2.svg"; hint: "Sound & brightness"; onClicked: RightPanel.shown = !RightPanel.shown }
            IconButton { visible: Settings.moduleEnabled("system"); Layout.alignment: Qt.AlignHCenter; iconName: "cpu.svg"; hint: "System readings"; onClicked: SysStatsPanel.toggle() }
            SystemTray { Layout.alignment: Qt.AlignHCenter }
        }
    }
    // Recovery access is always available even when every optional module is disabled.
    IconButton {
        anchors.bottom: parent.bottom; anchors.bottomMargin: 8; anchors.horizontalCenter: parent.horizontalCenter
        iconName: "settings-2.svg"; hint: "Your corner · Super+Ctrl+S"
        onClicked: SettingsPanel.toggle()
    }
}
