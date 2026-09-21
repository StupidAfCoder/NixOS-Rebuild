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
    readonly property var panels: [WallpaperLauncher, AppLauncher, PowerMenu, WifiPanel, BatteryPanel, TrayMenu, MediaPanel, BluetoothPanel, SysStatsPanel, SettingsPanel, WellbeingPanel, RightPanel]
    readonly property bool anyPanelShown: WallpaperLauncher.shown || AppLauncher.shown || PowerMenu.shown || WifiPanel.shown || BatteryPanel.shown || TrayMenu.shown || MediaPanel.shown || BluetoothPanel.shown || SysStatsPanel.shown || SettingsPanel.shown || WellbeingPanel.shown || RightPanel.shown
    function closeAll(except) {
        for (const panel of panels) if (panel !== except && panel.shown) {
            if (typeof panel.hide === "function") panel.hide(); else panel.shown = false;
        }
    }
    function activate(panel) {
        if (!panel.shown) return;
        popupScreen = Hyprland.focusedMonitor?.name || Quickshell.screens[0]?.name || "";
        closeAll(panel);
    }
    Connections { target: WallpaperLauncher; function onShownChanged() { manager.activate(WallpaperLauncher); } }
    Connections { target: AppLauncher; function onShownChanged() { manager.activate(AppLauncher); } }
    Connections { target: PowerMenu; function onShownChanged() { manager.activate(PowerMenu); } }
    Connections { target: WifiPanel; function onShownChanged() { manager.activate(WifiPanel); } }
    Connections { target: BatteryPanel; function onShownChanged() { manager.activate(BatteryPanel); } }
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
                        Rectangle { anchors.fill: parent; color: "black"; opacity: AppLauncher.shown || WallpaperLauncher.shown || WellbeingPanel.shown ? .25 : 0 }
                        MouseArea { anchors.fill: parent; onClicked: manager.closeAll(null) }
                    }
                    Item {
                        id: popups
                        anchors.fill: parent; z: 20
                        visible: frame.onScreen
                        Keys.onEscapePressed: manager.closeAll(null)
                        BluetoothPanelContent { shown: BluetoothPanel.shown && frame.onScreen }
                        PowerMenuContent { shown: PowerMenu.shown && frame.onScreen }
                        WifiPanelContent { shown: WifiPanel.shown && frame.onScreen }
                        BatteryPanelContent { shown: BatteryPanel.shown && frame.onScreen }
                        MediaPanelContent { shown: MediaPanel.shown && frame.onScreen }
                        WallpaperLauncherContent { shown: WallpaperLauncher.shown && frame.onScreen }
                        AppLauncherContent { shown: AppLauncher.shown && frame.onScreen }
                        SysStatsPanelContent { shown: SysStatsPanel.shown && frame.onScreen }
                        SettingsPanelContent { shown: SettingsPanel.shown && frame.onScreen }
                        WellbeingPanelContent { shown: WellbeingPanel.shown && frame.onScreen }
                        RightEdgePanel { shown: RightPanel.shown && frame.onScreen }
                        TrayMenuContent { visible: TrayMenu.shown && frame.onScreen }
                    }
                    Bar { id: barArea; anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; barWidth: manager.barWidth; z: 30 }
                    CornerAccent { corner: "topLeft"; thickness: manager.borderThickness; color: manager.accentColor; anchors.left: parent.left; anchors.top: parent.top; anchors.leftMargin: manager.barWidth; anchors.topMargin: manager.borderThickness }
                    CornerAccent { corner: "bottomLeft"; thickness: manager.borderThickness; color: manager.accentColor; anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.leftMargin: manager.barWidth; anchors.bottomMargin: manager.borderThickness }
                    CornerAccent { corner: "topRight"; thickness: manager.borderThickness; color: manager.accentColor; anchors.right: parent.right; anchors.top: parent.top; anchors.rightMargin: manager.borderThickness; anchors.topMargin: manager.borderThickness }
                    CornerAccent { corner: "bottomRight"; thickness: manager.borderThickness; color: manager.accentColor; anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.rightMargin: manager.borderThickness; anchors.bottomMargin: manager.borderThickness }
                }
            }
        }
    }
}
