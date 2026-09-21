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
import "../workspaces"
import "../workspaces/WorkspaceState.js" as WorkspaceState

Loader {
    id: root
    required property string moduleKey
    property real railHeight: 0
    property bool horizontal: false
    signal openPanel(var panel, var origin)
    signal workspaceHint(var origin)
    readonly property bool available: Settings.moduleEnabled(moduleKey)
        && (moduleKey !== "bluetooth" || Bluetooth.defaultAdapter !== null)
        && (moduleKey !== "tray" || TrayApps.items.length > 0)
    active: available
    visible: available
    sourceComponent: moduleKey === "workspaces" ? workspaces : moduleKey === "clock" ? clock
        : moduleKey === "wizard" ? wizard : moduleKey === "media" && !horizontal && railHeight > 920 && MprisActive.hasPlayer ? media : glyph
    function request(panel) { openPanel(panel, root); }
    readonly property var panel: ({launcher: AppLauncher, media: MediaPanel, audio: RightPanel,
        system: SysStatsPanel, battery: BatteryPanel, network: WifiPanel, bluetooth: BluetoothPanel,
        tray: TrayApps, settings: SettingsPanel, power: PowerMenu})[moduleKey] || null
    readonly property string icon: ({launcher: "nixos.svg", media: "music.svg", audio: "volume-2.svg",
        system: "cpu.svg", battery: UPower.displayDevice.ready && UPower.displayDevice.percentage < .2 ? "battery-low.svg" : "battery-full.svg",
        network: NetworkBackend.ethernetOnline ? "globe.svg" : "wifi.svg", bluetooth: !Bluetooth.defaultAdapter?.enabled ? "bluetooth-off.svg" : BluetoothPanel.connectedCount ? "bluetooth-connected.svg" : "bluetooth.svg",
        tray: "database.svg", settings: "settings-2.svg", power: "power.svg"})[moduleKey] || "app-windows.svg"
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
        Grid {
            spacing: 4
            columns: root.horizontal ? Settings.workspaceCount + 1 : 1
            Repeater {
                model: WorkspaceState.slots(Settings.workspaceCount, Hyprland.focusedWorkspace?.id || 0)
                PixelButton {
                    id: ws
                    required property int modelData
                    required property int index
                    Timer {
                        interval: 450
                        running: ws.hovered && ws.index === Settings.workspaceCount - 1 && !Settings.workspaceManagerButton && !WorkspacePanel.shown
                        onTriggered: root.workspaceHint(ws)
                    }
                    readonly property var workspace: Hyprland.workspaces.values.find(w => w.id === modelData)
                    readonly property bool isActive: Hyprland.focusedWorkspace?.id === modelData
                    readonly property bool occupied: !!workspace && workspace.toplevels.values.length > 0
                    width: 32; height: 28; padding: 4
                    quiet: true; checked: isActive
                    // Compositor selection never leaves a stale mouse-focus rectangle.
                    focusPolicy: Qt.NoFocus
                    Accessible.name: "Workspace " + (workspace?.name || modelData) + (occupied ? ", occupied" : ", empty")
                    contentItem: Item { WorkspaceMark { anchors.centerIn: parent; active: ws.isActive; occupied: ws.occupied } }
                    onClicked: WorkspacePanel.focusWorkspace(modelData)
                }
            }
            IconButton { visible: Settings.workspaceManagerButton; iconName: "app-windows.svg"; hint: "Manage all workspaces"; checked: WorkspacePanel.shown; onClicked: root.request(WorkspacePanel) }
        }
    }
    Component {
        id: clock
        PixelButton {
            implicitWidth: root.horizontal ? (Settings.clockShowDate ? 100 : 64) : 36
            implicitHeight: root.horizontal ? 36 : Settings.clockShowDate ? 80 : 44
            padding: 1; quiet: true; checked: WellbeingPanel.shown
            Accessible.name: Qt.formatDateTime(clockTimer.now, "dddd, d MMMM, HH:mm") + ", Your day"
            Timer { id: clockTimer; property date now: new Date(); interval: 1000; running: true; repeat: true; onTriggered: now = new Date() }
            contentItem: Item {
                GridLayout {
                    anchors.centerIn: parent
                    columns: root.horizontal ? 2 : 1
                    rowSpacing: 5; columnSpacing: 8
                    PixelText {
                        Layout.preferredWidth: root.horizontal ? 56 : 32
                        Layout.alignment: Qt.AlignCenter
                        horizontalAlignment: Text.AlignHCenter
                        text: Qt.formatTime(clockTimer.now, root.horizontal ? "HH:mm" : "HH\nmm")
                        font.family: "Silkscreen"; font.pixelSize: 14
                        lineHeight: .95
                    }
                    Item {
                        visible: Settings.clockShowDate
                        Layout.preferredWidth: 30; Layout.preferredHeight: 34
                        Layout.alignment: Qt.AlignCenter
                        // A tiny pixel calendar, using the same display face as the time.
                        Rectangle { x: 1; y: 4; width: parent.width - 2; height: 1; color: Colors.accent; opacity: .55 }
                        Rectangle { x: 4; y: 1; width: 2; height: 5; color: Colors.accent }
                        Rectangle { x: parent.width - 6; y: 1; width: 2; height: 5; color: Colors.accent }
                        PixelText {
                            x: 0; y: 8; width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: Qt.formatDate(clockTimer.now, "dd")
                            font.family: "Silkscreen"; font.pixelSize: 12; color: Colors.accent
                        }
                        PixelText {
                            x: 0; y: 24
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: Qt.formatDate(clockTimer.now, "MMM").toUpperCase()
                            font.family: "Silkscreen"; font.pixelSize: 8; color: Colors.accent
                        }
                    }
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
