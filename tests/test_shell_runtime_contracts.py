"""Source-level regression contracts; these are not a native Quickshell runtime."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]


class RuntimeContracts(unittest.TestCase):
    def test_filesystem_paths_do_not_strip_virtual_qml_urls(self):
        for file in (ROOT / 'quickshell').rglob('*.qml'):
            text = file.read_text()
            self.assertNotRegex(text, r'Qt\.resolvedUrl\([^\n]+replace\(["\']file:', str(file))
        settings = (ROOT / 'quickshell/common/Settings.qml').read_text()
        self.assertIn('Quickshell.shellPath("..")', settings)
        self.assertIn('Quickshell.env("PIXEL_SHELL_ROOT")', settings)
        icon = (ROOT / 'quickshell/bar/ColoredIcon.qml').read_text()
        self.assertIn('Quickshell.shellPath("bar/assets/icons/")', icon)

    def test_icon_source_is_pure_and_nonblocking(self):
        text = (ROOT / 'quickshell/bar/ColoredIcon.qml').read_text()
        source = text.split('    source:', 1)[1]
        self.assertNotIn('text()', source)
        self.assertNotIn('revision', text)
        self.assertNotIn('blockLoading: true', text)
        self.assertIn('onLoaded:', text)
        self.assertIn('svgData', source)

    def test_no_rail_tooltips_and_only_one_third_party_tray_control(self):
        for name in ['bar/Bar.qml', 'bar/BarModule.qml', 'common/IconButton.qml']:
            self.assertNotIn('ToolTip.', (ROOT / 'quickshell' / name).read_text())
        tray = (ROOT / 'quickshell/bar/BarModule.qml').read_text()
        self.assertEqual(tray.count('tray: TrayApps'), 1)
        self.assertNotIn('IconImage', tray)
        self.assertIn('TrayAppsContent', (ROOT / 'quickshell/bar/FrameWindow.qml').read_text())

    def test_decoder_lifetime_and_no_player_guard(self):
        power = (ROOT / 'quickshell/bar/PowerMenuContent.qml').read_text()
        self.assertIn('active: root.shown && !Settings.reducedMotion', power)
        self.assertIn('audioOutput: null', power)
        self.assertIn('Loader {', power)
        self.assertIn('root.shown && !!root.player &&', (ROOT / 'quickshell/bar/MediaPanelContent.qml').read_text())

    def test_launcher_schema_and_ui_agree(self):
        text = (ROOT / 'quickshell/common/Settings.qml').read_text()
        self.assertIn('["top", "bottom", "center"]', text)
        sheet = (ROOT / 'quickshell/common/Sheet.qml').read_text()
        self.assertIn('edge === "top"', sheet)
        self.assertIn('edge === "bottom"', sheet)
        self.assertIn('Settings.launcherEdge', (ROOT / 'quickshell/launcher/AppLauncherContent.qml').read_text())

    def test_bundled_icon_references_exist(self):
        for file in (ROOT / 'quickshell').rglob('*.qml'):
            for name in re.findall(r'(?:iconName|icon):\s*"([\w-]+\.svg)"', file.read_text()):
                self.assertTrue((ROOT / 'quickshell/bar/assets/icons' / name).is_file(), (file, name))

    def test_compact_sheets_and_recovery_access(self):
        sheet = (ROOT / 'quickshell/common/Sheet.qml').read_text()
        self.assertIn('body.implicitHeight + heading.implicitHeight', sheet)
        self.assertIn('property bool fitContent: true', sheet)
        launcher = (ROOT / 'quickshell/launcher/AppLauncherContent.qml').read_text()
        self.assertIn('fitContent: false', launcher)  # avoids a ListView height cycle
        self.assertIn('shellAction: "settings"', launcher)
        frame = (ROOT / 'quickshell/bar/FrameWindow.qml').read_text()
        self.assertIn('Region { item: settingsEdge }', frame)
        self.assertIn('text: "↓ Settings"', frame)
        self.assertIn('visible: settingsEdge.revealed', frame)
        self.assertNotIn('visible: settingsEdge.height >', frame)
        self.assertNotIn('anchors.bottomMargin: 46', (ROOT / 'quickshell/bar/Bar.qml').read_text())
        self.assertIn('Settings.moduleEnabled(moduleKey)', (ROOT / 'quickshell/bar/BarModule.qml').read_text())

    def test_workspace_selection_and_console_geometry(self):
        module = (ROOT / 'quickshell/bar/BarModule.qml').read_text()
        self.assertIn('checked: isActive', module)
        self.assertIn('Hyprland.focusedWorkspace?.id === modelData', module)
        self.assertIn('focusPolicy: Qt.NoFocus', module)
        self.assertNotIn('ws.activeFocus', module)
        self.assertIn('"HH:mm"', module)
        self.assertNotIn('hoverPreview', (ROOT / 'quickshell/bar/MediaBarWidget.qml').read_text())
        button = (ROOT / 'quickshell/common/PixelButton.qml').read_text()
        self.assertIn('background: ConsoleSurface', button)
        self.assertIn('root.visualFocus', button)
        self.assertIn('implicitContentWidth', button)  # works for overridden contentItem too
        self.assertNotIn('Colors.mix(Colors.surfaceContainer', button)  # checked text uses validated surfaces

    def test_wallpaper_split_and_image_previews(self):
        picker = (ROOT / 'quickshell/common/PathPicker.qml').read_text()
        self.assertIn('GridView {', picker)
        self.assertIn('sourceSize.width: 240', picker)
        self.assertIn('function isImage', picker)
        quick = (ROOT / 'quickshell/wallpaper/QuickWallpapersContent.qml').read_text()
        self.assertNotIn('\nSheet {', quick)
        self.assertNotIn('Sync live', quick)
        self.assertNotIn('Adjust colors', quick)
        self.assertIn('Keys.onRightPressed', quick)
        self.assertIn('userScrolling = false', quick)
        power = (ROOT / 'quickshell/bar/PowerMenuContent.qml').read_text()
        self.assertNotIn('ProfileAvatar', power)
        self.assertIn('MediaPlayer {', power)

    def test_preview_cancellation_is_global_not_per_monitor(self):
        controller = (ROOT / 'quickshell/wallpaper/WallpaperLauncher.qml').read_text()
        self.assertIn('onShownChanged: if (!shown) WallpaperBackend.cancelPreview()', controller)
        studio = (ROOT / 'quickshell/wallpaper/WallpaperLauncherContent.qml').read_text()
        self.assertIn('if (!shown) return;', studio)
        self.assertIn('function onContrastChanged() { root.preview(); }', studio)
        backend = (ROOT / 'quickshell/wallpaper/WallpaperBackend.qml').read_text()
        self.assertIn('previewProc.revision === previewRevision', backend)
        self.assertIn('root.finishPreview(code, revision, root.previewResult)', backend)

    def test_trash_selection_waits_for_success_and_both_views_observe_busy(self):
        studio = (ROOT / 'quickshell/wallpaper/WallpaperLauncherContent.qml').read_text()
        self.assertIn('function onWallpaperTrashed(path)', studio)
        self.assertIn('if (root.selectedPath === path) root.selectedPath = ""', studio)
        self.assertNotIn('WallpaperBackend.trash(root.selectedPath); root.selectedPath = ""', studio)
        for name in ['WallpaperLauncherContent', 'QuickWallpapersContent']:
            self.assertIn('|| WallpaperBackend.trashing', (ROOT / 'quickshell/wallpaper' / (name + '.qml')).read_text())

    def test_nested_tray_supplies_its_parent_monitor(self):
        tray = (ROOT / 'quickshell/bar/TrayAppsContent.qml').read_text()
        self.assertIn('TrayMenu.openFor(modelData, pos.x, pos.y, root.invokingScreen)', tray)
        frame = (ROOT / 'quickshell/bar/FrameWindow.qml').read_text()
        self.assertIn('TrayAppsContent { invokingScreen: frame.shellScreen.name;', frame)

    def test_file_picker_and_quick_wallpaper_registration(self):
        picker = (ROOT / 'quickshell/common/PathPicker.qml').read_text()
        self.assertIn('FolderListModel', picker)
        self.assertIn('signal chosen(string path)', picker)
        frame = (ROOT / 'quickshell/bar/FrameWindow.qml').read_text()
        self.assertIn('Region { item: wallpaperEdge }', frame)
        self.assertIn('QuickWallpapersContent', frame)
        self.assertNotIn('wallpaperEdge.latched', frame)
        self.assertIn('onClicked: controller.toggleFrom(QuickWallpapers, wallpaperEdge, frame.shellScreen.name)', frame)
        self.assertIn('call quickwallpaper toggle', (ROOT / 'hyprland.lua').read_text())

    def test_blur_switch_recreates_surface_without_mutating_namespace(self):
        manager = (ROOT / 'quickshell/bar/ShellFrame.qml').read_text()
        frame = (ROOT / 'quickshell/bar/FrameWindow.qml').read_text()
        self.assertIn('sourceComponent: Settings.barBlur ? blurredFrame : plainFrame', manager)
        self.assertIn('blurred: false', manager)
        self.assertIn('blurred: true', manager)
        self.assertNotIn('Settings.barBlur', frame)
        self.assertIn('blurred ? "quickshell:frame-blur" : "quickshell:frame"', frame)
        rules = (ROOT / 'hyprland.lua').read_text()
        self.assertIn('namespace = "^quickshell:frame-blur$"', rules)
        self.assertIn('ignore_alpha = 0.2', rules)
        self.assertIn('? .15 : 0', frame)  # scrim below blur threshold
        settings = (ROOT / 'quickshell/common/Settings.qml').read_text()
        self.assertIn('bounded("barOpacity", 1, .35, 1)', settings)
        self.assertIn('SettingsPanel.currentTab', (ROOT / 'quickshell/settings/SettingsPanelContent.qml').read_text())

    def test_four_edge_struts_and_popup_origins_share_geometry(self):
        manager = (ROOT / 'quickshell/bar/ShellFrame.qml').read_text()
        for edge in ('left', 'right', 'top', 'bottom'):
            self.assertIn('exclusiveZone: Settings.desktopInsets.' + edge, manager)
        frame = (ROOT / 'quickshell/bar/FrameWindow.qml').read_text()
        self.assertIn('Geometry.barRect(width, height, Settings.barEdge, Settings.barWidth)', frame)
        for line in frame.splitlines():
            if 'anchorY: controller.popupAnchorY' in line:
                self.assertIn('anchorX: controller.popupAnchorX', line)
        for name in ('left', 'right', 'top', 'bottom'):
            self.assertIn('anchors.' + name + 'Margin: Settings.desktopInsets.' + name, frame)
        sheet = (ROOT / 'quickshell/common/Sheet.qml').read_text()
        self.assertIn('Placement.panelPosition(area, width, height, Settings.barEdge, centered, anchorX, anchorY)', sheet)

    def test_mouse_collection_navigation_and_click_only_edge(self):
        frame = (ROOT / 'quickshell/bar/FrameWindow.qml').read_text()
        edge = frame.split('id: wallpaperEdge', 1)[1].split('id: settingsEdge', 1)[0]
        self.assertNotIn('Timer', edge)
        self.assertNotIn('onEntered', edge)
        self.assertIn('onClicked: controller.toggleFrom(QuickWallpapers', edge)
        quick = (ROOT / 'quickshell/wallpaper/QuickWallpapersContent.qml').read_text()
        self.assertIn('onMoved: root.scrubTo(Math.round(value))', quick)
        self.assertIn('!carousel.dragging && !carousel.flicking', quick)
        studio = (ROOT / 'quickshell/wallpaper/WallpaperLauncherContent.qml').read_text()
        self.assertIn('ScrollBar.vertical: CollectionScrollBar', studio)
        scroll = (ROOT / 'quickshell/common/CollectionScrollBar.qml').read_text()
        self.assertIn('policy: ScrollBar.AlwaysOn', scroll)
        self.assertIn('interactive: true', scroll)

    def test_minimal_copy_keeps_safety_and_real_option_descriptions(self):
        settings = (ROOT / 'quickshell/settings/SettingsPanelContent.qml').read_text()
        self.assertIn('description: modelData.description', settings)
        self.assertIn('No titles, URLs or keystrokes.', settings)
        self.assertIn('Shared browser processes', settings)
        studio = (ROOT / 'quickshell/wallpaper/WallpaperLauncherContent.qml').read_text()
        self.assertIn('Writes LIVE Wallust templates', studio)
        self.assertNotIn('Seed ', studio)
        self.assertNotIn('Choose a cartridge to launch.', (ROOT / 'quickshell/launcher/AppLauncherContent.qml').read_text())
        day = (ROOT / 'quickshell/wellbeing/WellbeingPanelContent.qml').read_text()
        self.assertNotIn('Blank = no data', day)
        self.assertIn('Usage.sampleData ? "Demo"', day)

    def test_workspaces_have_recovery_access_and_moves_are_preview_guarded(self):
        launcher = (ROOT / 'quickshell/launcher/AppLauncherContent.qml').read_text()
        self.assertIn('shellAction: "workspaces"', launcher)
        self.assertIn('call workspaces toggle', (ROOT / 'hyprland.lua').read_text())
        panel = (ROOT / 'quickshell/workspaces/WorkspacePanelContent.qml').read_text()
        self.assertIn('Hyprland.toplevels.values.some', panel)
        self.assertIn('alive && !Settings.previewMode', panel)
        self.assertIn('enabled: !Settings.previewMode', panel)
        bar = (ROOT / 'quickshell/bar/BarModule.qml').read_text()
        self.assertIn('WorkspaceMark', bar)
        self.assertNotIn('text: String(ws.', bar)
        self.assertIn('font.pixelSize: 11; color: Colors.accent', bar)
