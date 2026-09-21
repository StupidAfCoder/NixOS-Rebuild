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
        for name in ['bar/Bar.qml', 'bar/SystemTray.qml', 'common/IconButton.qml']:
            self.assertNotIn('ToolTip.', (ROOT / 'quickshell' / name).read_text())
        tray = (ROOT / 'quickshell/bar/SystemTray.qml').read_text()
        self.assertIn('TrayApps.toggle()', tray)
        self.assertNotIn('IconImage', tray)
        self.assertNotIn('Repeater', tray)
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
