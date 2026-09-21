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

Scope {
    id: manager
    property int barWidth: Settings.barWidth
    property int borderThickness: Settings.frameWidth
    property color frameColor: Colors.background
    property color accentColor: Colors.accent
    property string popupScreen: ""
    property real popupAnchorY: -1
    property real pendingAnchorY: -1
    property string pendingScreen: ""
    function toggleFrom(panel, origin, screenName) {
        if (panel.shown) {
            if (popupScreen !== screenName) {
                popupScreen = screenName;
                popupAnchorY = origin.mapToItem(null, 0, origin.height / 2).y;
            } else if (typeof panel.hide === "function") panel.hide(); else panel.shown = false;
            return;
        }
        pendingAnchorY = origin.mapToItem(null, 0, origin.height / 2).y;
        pendingScreen = screenName;
        // Some panels do work on open (device refresh, draft reset).
        if (typeof panel.open === "function") panel.open();
        else if (typeof panel.toggle === "function") panel.toggle();
        else panel.shown = true;
        pendingAnchorY = -1; pendingScreen = "";
    }
    readonly property var panels: [QuickWallpapers, WallpaperLauncher, AppLauncher, PowerMenu, WifiPanel, BatteryPanel, TrayApps, TrayMenu, MediaPanel, BluetoothPanel, SysStatsPanel, SettingsPanel, WellbeingPanel, RightPanel]
    readonly property bool anyPanelShown: QuickWallpapers.shown || WallpaperLauncher.shown || AppLauncher.shown || PowerMenu.shown || WifiPanel.shown || BatteryPanel.shown || TrayApps.shown || TrayMenu.shown || MediaPanel.shown || BluetoothPanel.shown || SysStatsPanel.shown || SettingsPanel.shown || WellbeingPanel.shown || RightPanel.shown
    function closeAll(except) {
        for (const panel of panels) if (panel !== except && panel.shown) {
            if (typeof panel.hide === "function") panel.hide(); else panel.shown = false;
        }
    }
    function activate(panel) {
        if (!panel.shown) return;
        popupScreen = pendingScreen || Hyprland.focusedMonitor?.name || Quickshell.screens[0]?.name || "";
        popupAnchorY = pendingAnchorY;
        closeAll(panel);
    }
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
                    implicitWidth: manager.barWidth; exclusiveZone: manager.barWidth; color: "transparent"
                }
                PanelWindow {
                    screen: screenRoot.modelData
                    WlrLayershell.namespace: "quickshell:strut-top"
                    anchors { top: true; left: true; right: true }
                    implicitHeight: manager.borderThickness; exclusiveZone: manager.borderThickness; color: "transparent"
                }
                PanelWindow {
                    screen: screenRoot.modelData
                    WlrLayershell.namespace: "quickshell:strut-bottom"
                    anchors { bottom: true; left: true; right: true }
                    implicitHeight: manager.borderThickness; exclusiveZone: manager.borderThickness; color: "transparent"
                }
                PanelWindow {
                    screen: screenRoot.modelData
                    WlrLayershell.namespace: "quickshell:strut-right"
                    anchors { top: true; bottom: true; right: true }
                    implicitWidth: manager.borderThickness; exclusiveZone: manager.borderThickness; color: "transparent"
                }
                PanelWindow {
                    id: frame
                    screen: screenRoot.modelData
                    anchors { top: true; bottom: true; left: true; right: true }
                    color: "transparent"
                    exclusionMode: ExclusionMode.Ignore
                    WlrLayershell.layer: WlrLayer.Top
                    WlrLayershell.namespace: "quickshell:frame"
                    readonly property bool onScreen: manager.popupScreen === screenRoot.modelData.name
                    readonly property bool openHere: onScreen && manager.anyPanelShown
                    WlrLayershell.keyboardFocus: openHere ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
                    mask: Region {
                        Region { item: barArea }
                        Region { item: wallpaperEdge }
                        Region { item: settingsEdge }
                        Region { item: catchArea }
                    }
                    Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; height: manager.borderThickness; color: manager.frameColor }
                    Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: manager.borderThickness; color: manager.frameColor }
                    Rectangle { anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.right: parent.right; width: manager.borderThickness; color: manager.frameColor }
                    Item {
                        id: catchArea
                        width: frame.openHere ? parent.width : 0
                        height: frame.openHere ? parent.height : 0
                        z: 10
                        Rectangle { anchors.fill: parent; color: "black"; opacity: WallpaperLauncher.shown || (AppLauncher.shown && Settings.launcherEdge === "center") ? .15 : 0 }
                        MouseArea { anchors.fill: parent; onClicked: manager.closeAll(null) }
                    }
                    Item {
                        id: wallpaperEdge
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        width: Settings.quickWallpaperEdgeEnabled ? Math.max(4, manager.borderThickness) : 0
                        height: Math.min(160, parent.height / 3); z: 15
                        property bool latched: false
                        Rectangle { anchors.fill: parent; color: edgeMouse.containsMouse ? Colors.accent : "transparent" }
                        MouseArea { id: edgeMouse; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton; onExited: wallpaperEdge.latched = false }
                        Timer {
                            interval: 650
                            running: edgeMouse.containsMouse && !wallpaperEdge.latched && !manager.anyPanelShown && Settings.quickWallpaperEdgeEnabled && !(Hyprland.focusedWorkspace?.lastIpcObject?.hasfullscreen ?? false)
                            onTriggered: { wallpaperEdge.latched = true; QuickWallpapers.open(); manager.popupScreen = screenRoot.modelData.name; }
                        }
                    }
                    Item {
                        id: settingsEdge
                        anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
                        z: 31; width: 140
                        readonly property bool available: !manager.anyPanelShown && !(Hyprland.focusedWorkspace?.lastIpcObject?.hasfullscreen ?? false)
                        readonly property bool revealed: available && settingsHover.hovered
                        height: !available ? 0 : revealed ? 42 : Math.max(4, manager.borderThickness)
                        // The edge target itself costs no rail slot and does not open a
                        // drawer accidentally: first reveal the label, then click it.
                        HoverHandler { id: settingsHover }
                        PixelButton {
                            id: settingsHandle
                            anchors.horizontalCenter: parent.horizontalCenter; y: 6
                            width: 132; height: 32; text: "↓ Settings"
                            visible: settingsEdge.revealed
                            onClicked: manager.toggleFrom(SettingsPanel, settingsHandle, screenRoot.modelData.name)
                        }
                    }
                    Item {
                        id: popups
                        anchors.fill: parent; z: 20
                        visible: frame.onScreen
                        Keys.onEscapePressed: manager.closeAll(null)
                        BluetoothPanelContent { anchorY: manager.popupAnchorY; shown: BluetoothPanel.shown && frame.onScreen }
                        PowerMenuContent { anchorY: manager.popupAnchorY; shown: PowerMenu.shown && frame.onScreen }
                        WifiPanelContent { anchorY: manager.popupAnchorY; shown: WifiPanel.shown && frame.onScreen }
                        BatteryPanelContent { anchorY: manager.popupAnchorY; shown: BatteryPanel.shown && frame.onScreen }
                        MediaPanelContent { anchorY: manager.popupAnchorY; shown: MediaPanel.shown && frame.onScreen }
                        QuickWallpapersContent { shown: QuickWallpapers.shown && frame.onScreen }
                        WallpaperLauncherContent { shown: WallpaperLauncher.shown && frame.onScreen }
                        AppLauncherContent { shown: AppLauncher.shown && frame.onScreen }
                        SysStatsPanelContent { anchorY: manager.popupAnchorY; shown: SysStatsPanel.shown && frame.onScreen }
                        SettingsPanelContent { anchorY: manager.popupAnchorY; shown: SettingsPanel.shown && frame.onScreen }
                        WellbeingPanelContent { anchorY: manager.popupAnchorY; shown: WellbeingPanel.shown && frame.onScreen }
                        RightEdgePanel { anchorY: manager.popupAnchorY; shown: RightPanel.shown && frame.onScreen }
                        TrayAppsContent { anchorY: manager.popupAnchorY; shown: TrayApps.shown && frame.onScreen }
                        TrayMenuContent { visible: TrayMenu.shown && frame.onScreen }
                    }
                    Bar { id: barArea; anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; barWidth: manager.barWidth; z: 30; onOpenPanel: (panel, origin) => manager.toggleFrom(panel, origin, screenRoot.modelData.name) }
                    CornerAccent { corner: "topLeft"; thickness: manager.borderThickness; color: manager.accentColor; anchors.left: parent.left; anchors.top: parent.top; anchors.leftMargin: manager.barWidth; anchors.topMargin: manager.borderThickness }
                    CornerAccent { corner: "bottomLeft"; thickness: manager.borderThickness; color: manager.accentColor; anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.leftMargin: manager.barWidth; anchors.bottomMargin: manager.borderThickness }
                    CornerAccent { corner: "topRight"; thickness: manager.borderThickness; color: manager.accentColor; anchors.right: parent.right; anchors.top: parent.top; anchors.rightMargin: manager.borderThickness; anchors.topMargin: manager.borderThickness }
                    CornerAccent { corner: "bottomRight"; thickness: manager.borderThickness; color: manager.accentColor; anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.rightMargin: manager.borderThickness; anchors.bottomMargin: manager.borderThickness }
                }
            }
        }
    }
}
