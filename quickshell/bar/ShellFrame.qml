import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "../common"
import "../wallpaper"
import "../launcher"
import "../osd"
import "../sysstats"
import "../settings"
import "../wellbeing"
import "../workspaces"

Scope {
    id: manager
    property int barWidth: Settings.barWidth
    property int borderThickness: Settings.frameWidth
    property color frameColor: Colors.background
    property color accentColor: Colors.accent
    property string popupScreen: ""
    property real popupAnchorY: -1
    property real popupAnchorX: -1
    property real pendingAnchorY: -1
    property real pendingAnchorX: -1
    property string pendingScreen: ""
    function toggleFrom(panel, origin, screenName) {
        if (panel.shown) {
            if (popupScreen !== screenName) {
                popupScreen = screenName;
                const point = origin.mapToItem(null, origin.width / 2, origin.height / 2);
                popupAnchorY = point.y; popupAnchorX = point.x;
            } else if (typeof panel.hide === "function") panel.hide(); else panel.shown = false;
            return;
        }
        const point = origin.mapToItem(null, origin.width / 2, origin.height / 2);
        pendingAnchorY = point.y; pendingAnchorX = point.x;
        pendingScreen = screenName;
        // Some panels do work on open (device refresh, draft reset).
        if (typeof panel.open === "function") panel.open();
        else if (typeof panel.toggle === "function") panel.toggle();
        else panel.shown = true;
        pendingAnchorY = -1; pendingAnchorX = -1; pendingScreen = "";
    }
    readonly property var panels: [WorkspacePanel, QuickWallpapers, WallpaperLauncher, AppLauncher, PowerMenu, WifiPanel, BatteryPanel, TrayApps, TrayMenu, MediaPanel, BluetoothPanel, SysStatsPanel, SettingsPanel, WellbeingPanel, RightPanel]
    readonly property bool anyPanelShown: WorkspacePanel.shown || QuickWallpapers.shown || WallpaperLauncher.shown || AppLauncher.shown || PowerMenu.shown || WifiPanel.shown || BatteryPanel.shown || TrayApps.shown || TrayMenu.shown || MediaPanel.shown || BluetoothPanel.shown || SysStatsPanel.shown || SettingsPanel.shown || WellbeingPanel.shown || RightPanel.shown
    function closeAll(except) {
        for (const panel of panels) if (panel !== except && panel.shown) {
            if (typeof panel.hide === "function") panel.hide(); else panel.shown = false;
        }
    }
    function activate(panel) {
        if (!panel.shown) return;
        // Nested tray menus already have window-local coordinates from their
        // parent panel; switching to another monitor would invalidate them.
        popupScreen = (panel === TrayMenu ? TrayMenu.requestedScreen : "") || pendingScreen || Hyprland.focusedMonitor?.name || Quickshell.screens[0]?.name || "";
        popupAnchorY = pendingAnchorY; popupAnchorX = pendingAnchorX;
        closeAll(panel);
    }
    Connections { target: WorkspacePanel; function onShownChanged() { manager.activate(WorkspacePanel); } }
    Connections { target: QuickWallpapers; function onShownChanged() { manager.activate(QuickWallpapers); } }
    Connections { target: WallpaperLauncher; function onShownChanged() { manager.activate(WallpaperLauncher); } }
    Connections { target: AppLauncher; function onShownChanged() { manager.activate(AppLauncher); } }
    Connections { target: PowerMenu; function onShownChanged() { manager.activate(PowerMenu); } }
    Connections { target: WifiPanel; function onShownChanged() { manager.activate(WifiPanel); } }
    Connections { target: BatteryPanel; function onShownChanged() { manager.activate(BatteryPanel); } }
    Connections { target: TrayApps; function onShownChanged() { manager.activate(TrayApps); } }
    Connections { target: TrayMenu; function onShownChanged() { manager.activate(TrayMenu); } }
    Connections { target: MediaPanel; function onShownChanged() { manager.activate(MediaPanel); } }
    Connections { target: BluetoothPanel; function onShownChanged() { manager.activate(BluetoothPanel); } }
    Connections { target: SysStatsPanel; function onShownChanged() { manager.activate(SysStatsPanel); } }
    Connections { target: SettingsPanel; function onShownChanged() { manager.activate(SettingsPanel); } }
    Connections { target: WellbeingPanel; function onShownChanged() { manager.activate(WellbeingPanel); } }
    Connections { target: RightPanel; function onShownChanged() { manager.activate(RightPanel); } }

    Variants {
        model: Quickshell.screens
        delegate: Component {
            Item {
                id: screenRoot
                required property var modelData
                PanelWindow {
                    screen: screenRoot.modelData
                    WlrLayershell.namespace: "quickshell:strut-left"
                    anchors { top: true; bottom: true; left: true }
                    implicitWidth: Settings.desktopInsets.left; exclusiveZone: Settings.desktopInsets.left; color: "transparent"
                }
                PanelWindow {
                    screen: screenRoot.modelData
                    WlrLayershell.namespace: "quickshell:strut-top"
                    anchors { top: true; left: true; right: true }
                    implicitHeight: Settings.desktopInsets.top; exclusiveZone: Settings.desktopInsets.top; color: "transparent"
                }
                PanelWindow {
                    screen: screenRoot.modelData
                    WlrLayershell.namespace: "quickshell:strut-bottom"
                    anchors { bottom: true; left: true; right: true }
                    implicitHeight: Settings.desktopInsets.bottom; exclusiveZone: Settings.desktopInsets.bottom; color: "transparent"
                }
                PanelWindow {
                    screen: screenRoot.modelData
                    WlrLayershell.namespace: "quickshell:strut-right"
                    anchors { top: true; bottom: true; right: true }
                    implicitWidth: Settings.desktopInsets.right; exclusiveZone: Settings.desktopInsets.right; color: "transparent"
                }
                // Switching Components recreates only this surface, with a fresh
                // immutable namespace. Backends/jobs and struts stay alive.
                Loader {
                    sourceComponent: Settings.barBlur ? blurredFrame : plainFrame
                }
                Component { id: plainFrame; FrameWindow { controller: manager; shellScreen: screenRoot.modelData; blurred: false } }
                Component { id: blurredFrame; FrameWindow { controller: manager; shellScreen: screenRoot.modelData; blurred: true } }

            }
        }
    }
}
