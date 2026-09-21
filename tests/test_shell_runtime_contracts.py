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
        self.assertIn('TrayAppsContent', (ROOT / 'quickshell/bar/ShellFrame.qml').read_text())

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
        frame = (ROOT / 'quickshell/bar/ShellFrame.qml').read_text()
        self.assertIn('Region { item: settingsEdge }', frame)
        self.assertIn('text: "↓ Settings"', frame)
        self.assertIn('visible: settingsEdge.revealed', frame)
        self.assertNotIn('visible: settingsEdge.height >', frame)
        self.assertNotIn('anchors.bottomMargin: 46', (ROOT / 'quickshell/bar/Bar.qml').read_text())
        self.assertIn('Settings.moduleEnabled(moduleKey)', (ROOT / 'quickshell/bar/BarModule.qml').read_text())

    def test_workspace_selection_and_console_geometry(self):
        module = (ROOT / 'quickshell/bar/BarModule.qml').read_text()
        self.assertIn('checked: isActive', module)
        self.assertIn('Hyprland.focusedWorkspace?.id === wsId', module)
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

    def test_file_picker_and_quick_wallpaper_registration(self):
        picker = (ROOT / 'quickshell/common/PathPicker.qml').read_text()
        self.assertIn('FolderListModel', picker)
        self.assertIn('signal chosen(string path)', picker)
        frame = (ROOT / 'quickshell/bar/ShellFrame.qml').read_text()
        self.assertIn('Region { item: wallpaperEdge }', frame)
        self.assertIn('QuickWallpapersContent', frame)
        self.assertIn('wallpaperEdge.latched', frame)
        self.assertIn('call quickwallpaper toggle', (ROOT / 'hyprland.lua').read_text())
