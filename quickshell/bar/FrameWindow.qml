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

import "../common/PopupGeometry.js" as Geometry

PanelWindow {
    id: frame
    required property var controller
    required property var shellScreen
    // Set by a static Component. Never mutate a connected layer's namespace.
    property bool blurred: false
    readonly property var railRect: Geometry.barRect(width, height, Settings.barEdge, Settings.barWidth)
    screen: frame.shellScreen
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: blurred ? "quickshell:frame-blur" : "quickshell:frame"
    readonly property bool onScreen: controller.popupScreen === frame.shellScreen.name
    readonly property bool openHere: onScreen && controller.anyPanelShown
    WlrLayershell.keyboardFocus: openHere ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    mask: Region {
        Region { item: barArea }
        Region { item: wallpaperEdge }
        Region { item: settingsEdge }
        Region { item: catchArea }
    }
    Rectangle { visible: Settings.barEdge !== "top"; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; height: Settings.frameWidth; color: controller.frameColor }
    Rectangle { visible: Settings.barEdge !== "bottom"; anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: Settings.frameWidth; color: controller.frameColor }
    Rectangle { visible: Settings.barEdge !== "right"; anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.right: parent.right; width: Settings.frameWidth; color: controller.frameColor }
    Rectangle { visible: Settings.barEdge !== "left"; anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.left: parent.left; width: Settings.frameWidth; color: controller.frameColor }
    Item {
        id: catchArea
        width: frame.openHere ? parent.width : 0
        height: frame.openHere ? parent.height : 0
        z: 10
        Rectangle { anchors.fill: parent; color: "black"; opacity: WallpaperLauncher.shown || (AppLauncher.shown && Settings.launcherEdge === "center") ? .15 : 0 }
        MouseArea { anchors.fill: parent; onClicked: controller.closeAll(null) }
    }
    Item {
        id: wallpaperEdge
        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
        readonly property bool available: Settings.quickWallpaperEdgeEnabled && !controller.anyPanelShown && !(Hyprland.focusedWorkspace?.lastIpcObject?.hasfullscreen ?? false)
        width: available ? Math.max(4, Settings.frameWidth) : 0
        height: Math.min(160, parent.height / 3); z: 32
        Rectangle { anchors.fill: parent; color: edgeMouse.containsMouse ? Colors.accent : "transparent" }
        MouseArea {
            id: edgeMouse; anchors.fill: parent; hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: controller.toggleFrom(QuickWallpapers, wallpaperEdge, frame.shellScreen.name)
        }
    }
    Item {
        id: settingsEdge
        anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
        z: 31; width: 140
        readonly property bool available: !controller.anyPanelShown && !(Hyprland.focusedWorkspace?.lastIpcObject?.hasfullscreen ?? false)
        readonly property bool revealed: available && settingsHover.hovered
        height: !available ? 0 : revealed ? 42 : Math.max(4, controller.borderThickness)
        // The edge target itself costs no rail slot and does not open a
        // drawer accidentally: first reveal the label, then click it.
        HoverHandler { id: settingsHover }
        PixelButton {
            id: settingsHandle
            anchors.horizontalCenter: parent.horizontalCenter; y: 6
            width: 132; height: 32; text: "↓ Settings"
            visible: settingsEdge.revealed
            onClicked: controller.toggleFrom(SettingsPanel, settingsHandle, frame.shellScreen.name)
        }
    }
    Item {
        id: popups
        anchors.fill: parent; z: 20
        visible: frame.onScreen
        Keys.onEscapePressed: controller.closeAll(null)
        WorkspacePanelContent { anchorX: controller.popupAnchorX; anchorY: controller.popupAnchorY; shown: WorkspacePanel.shown && frame.onScreen }
        BluetoothPanelContent { anchorX: controller.popupAnchorX; anchorY: controller.popupAnchorY; shown: BluetoothPanel.shown && frame.onScreen }
        PowerMenuContent { anchorX: controller.popupAnchorX; anchorY: controller.popupAnchorY; shown: PowerMenu.shown && frame.onScreen }
        WifiPanelContent { anchorX: controller.popupAnchorX; anchorY: controller.popupAnchorY; shown: WifiPanel.shown && frame.onScreen }
        BatteryPanelContent { anchorX: controller.popupAnchorX; anchorY: controller.popupAnchorY; shown: BatteryPanel.shown && frame.onScreen }
        MediaPanelContent { anchorX: controller.popupAnchorX; anchorY: controller.popupAnchorY; shown: MediaPanel.shown && frame.onScreen }
        QuickWallpapersContent { shown: QuickWallpapers.shown && frame.onScreen }
        WallpaperLauncherContent { shown: WallpaperLauncher.shown && frame.onScreen }
        AppLauncherContent { shown: AppLauncher.shown && frame.onScreen }
        SysStatsPanelContent { anchorX: controller.popupAnchorX; anchorY: controller.popupAnchorY; shown: SysStatsPanel.shown && frame.onScreen }
        SettingsPanelContent { anchorX: controller.popupAnchorX; anchorY: controller.popupAnchorY; shown: SettingsPanel.shown && frame.onScreen }
        WellbeingPanelContent { anchorX: controller.popupAnchorX; anchorY: controller.popupAnchorY; shown: WellbeingPanel.shown && frame.onScreen }
        RightEdgePanel { anchorX: controller.popupAnchorX; anchorY: controller.popupAnchorY; shown: RightPanel.shown && frame.onScreen }
        TrayAppsContent { invokingScreen: frame.shellScreen.name; anchorX: controller.popupAnchorX; anchorY: controller.popupAnchorY; shown: TrayApps.shown && frame.onScreen }
        TrayMenuContent { visible: TrayMenu.shown && frame.onScreen }
    }
    Bar { id: barArea; x: frame.railRect.x; y: frame.railRect.y; width: frame.railRect.width; height: frame.railRect.height; barWidth: controller.barWidth; z: 30; onOpenPanel: (panel, origin) => controller.toggleFrom(panel, origin, frame.shellScreen.name) }
    CornerAccent { corner: "topLeft"; thickness: controller.borderThickness; color: controller.accentColor; anchors.left: parent.left; anchors.top: parent.top; anchors.leftMargin: Settings.desktopInsets.left; anchors.topMargin: Settings.desktopInsets.top }
    CornerAccent { corner: "bottomLeft"; thickness: controller.borderThickness; color: controller.accentColor; anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.leftMargin: Settings.desktopInsets.left; anchors.bottomMargin: Settings.desktopInsets.bottom }
    CornerAccent { corner: "topRight"; thickness: controller.borderThickness; color: controller.accentColor; anchors.right: parent.right; anchors.top: parent.top; anchors.rightMargin: Settings.desktopInsets.right; anchors.topMargin: Settings.desktopInsets.top }
    CornerAccent { corner: "bottomRight"; thickness: controller.borderThickness; color: controller.accentColor; anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.rightMargin: Settings.desktopInsets.right; anchors.bottomMargin: Settings.desktopInsets.bottom }
}
