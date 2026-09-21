pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Bluetooth
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

Loader {
    id: root
    required property string moduleKey
    property real railHeight: 0
    signal openPanel(var panel, var origin)
    readonly property bool available: Settings.moduleEnabled(moduleKey)
        && (moduleKey !== "bluetooth" || Bluetooth.defaultAdapter !== null)
        && (moduleKey !== "tray" || TrayApps.items.length > 0)
    active: available
    visible: available
    sourceComponent: moduleKey === "workspaces" ? workspaces : moduleKey === "clock" ? clock
        : moduleKey === "wizard" ? wizard : moduleKey === "media" && railHeight > 920 && MprisActive.hasPlayer ? media : glyph
    function request(panel) { openPanel(panel, root); }
    readonly property var panel: ({launcher: AppLauncher, media: MediaPanel, audio: RightPanel,
        system: SysStatsPanel, battery: BatteryPanel, network: WifiPanel, bluetooth: BluetoothPanel,
        tray: TrayApps, settings: SettingsPanel, power: PowerMenu})[moduleKey] || null
    readonly property string icon: ({launcher: "nixos.svg", media: "music.svg", audio: "volume-2.svg",
        system: "cpu.svg", battery: UPower.displayDevice.ready && UPower.displayDevice.percentage < .2 ? "battery-low.svg" : "battery-full.svg",
        network: NetworkBackend.ethernetOnline ? "globe.svg" : "wifi.svg", bluetooth: !Bluetooth.defaultAdapter?.enabled ? "bluetooth-off.svg" : BluetoothPanel.connectedCount ? "bluetooth-connected.svg" : "bluetooth.svg",
        tray: "database.svg", settings: "settings-2.svg", power: "power.svg"})[moduleKey] || "app-windows.svg"
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

    Component {
        id: glyph
        IconButton {
            iconName: root.icon
            hint: Settings.moduleCatalog.find(m => m.key === root.moduleKey)?.label || root.moduleKey
            checked: root.panel?.shown ?? false
            onClicked: if (root.panel) root.request(root.panel)
        }
    }
    Component {
        id: workspaces
        Column {
            spacing: 4
            width: 32
            Timer { interval: 2000; running: root.available; repeat: true; onTriggered: Hyprland.refreshToplevels() }
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
                    width: 32; height: 28; padding: 4
                    quiet: true; checked: isActive
                    // The compositor owns selection. A click must not leave a second
                    // keyboard-focus outline when Hyprland changes workspace externally.
                    focusPolicy: Qt.NoFocus
                    Accessible.name: "Workspace " + wsId + (occupied ? ", occupied" : ", empty")
                    contentItem: Item {
                        ColoredIcon { anchors.centerIn: parent; width: 16; height: 16; visible: ws.occupied; iconName: root.iconForClass(ws.topWindow?.lastIpcObject?.class || ""); tint: ws.isActive ? Colors.accent : Colors.textOnSurfaceVariant }
                        PixelText { anchors.centerIn: parent; visible: !ws.occupied; text: String(ws.wsId).padStart(2, "0"); font.pixelSize: 12; color: ws.isActive ? Colors.accent : Colors.textOnSurfaceVariant }
                        Rectangle { x: -2; y: parent.height / 2 - 2; width: 2; height: 4; visible: ws.occupied; color: ws.isActive ? Colors.accent : Colors.outline }
                    }
                    onClicked: Hyprland.dispatch('hl.dsp.focus({ workspace = "' + ws.wsId + '" })')
                }
            }
        }
    }
    Component {
        id: clock
        PixelButton {
            implicitWidth: 36; implicitHeight: Settings.clockShowDate ? 46 : 32
            padding: 1; quiet: true; checked: WellbeingPanel.shown
            Accessible.name: "Clock and Your day"
            Timer { id: clockTimer; property date now: new Date(); interval: 1000; running: true; repeat: true; onTriggered: now = new Date() }
            contentItem: Item {
                Column {
                    anchors.centerIn: parent; width: parent.width; spacing: 4
                    PixelText { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: Qt.formatTime(clockTimer.now, "HH:mm"); font.pixelSize: 12 }
                    PixelText { visible: Settings.clockShowDate; width: parent.width; horizontalAlignment: Text.AlignHCenter; text: Qt.formatDate(clockTimer.now, "dd/MM"); font.pixelSize: 12; color: Colors.textOnSurfaceVariant }
                }
            }
            onClicked: root.request(WellbeingPanel)
        }
    }
    Component {
        id: wizard
        PixelButton {
            implicitWidth: 36; implicitHeight: 36; padding: 6
            quiet: true; checked: WallpaperLauncher.shown
            Accessible.name: "Wallpaper wizard"
            contentItem: ReactiveImage { path: Settings.cacheDir + "/wizard-idle.png"; fallbackSource: Settings.fileUrl(Quickshell.shellPath("bar/assets/wizard-template.png")) }
            onClicked: root.request(WallpaperLauncher)
        }
    }
    Component {
        id: media
        PixelButton {
            implicitWidth: 32; implicitHeight: 150; quiet: true; checked: MediaPanel.shown
            Accessible.name: "Now playing"
            contentItem: MediaBarWidget {}
            onClicked: root.request(MediaPanel)
        }
    }
}
