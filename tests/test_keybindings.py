"""No live compositor requests: protocol tests use mocks and Lua uses inert handles."""
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('keys', ROOT / 'scripts/shell-keybindings.py')
keys = importlib.util.module_from_spec(spec)
spec.loader.exec_module(keys)
try:
    from lupa import LuaRuntime
except ImportError:
    LuaRuntime = None


class KeybindingTests(unittest.TestCase):
    def test_defaults_match_shipped_lua_and_avoid_screenshot_collision(self):
        config = keys.validate(keys.defaults())
        self.assertEqual(keys.render(config), (ROOT / 'scripts/shell-keybindings-defaults.lua').read_text())
        self.assertEqual(keys.effective(config, 'settings'), 'CTRL + ALT + comma')
        self.assertEqual(len(keys.rows(config)), 7)

    def test_shared_modifier_custom_chords_and_disabled_actions(self):
        config = keys.defaults()
        config['shared'] = 'Win + control'
        config['actions']['settings'] = {'shared': False, 'enabled': True, 'key': 'f8'}
        config['actions']['power']['enabled'] = False
        result = keys.validate(config)
        self.assertEqual(keys.effective(result, 'launcher'), 'CTRL + SUPER + space')
        self.assertEqual(keys.effective(result, 'settings'), 'F8')
        self.assertEqual(len(keys.rows(result)), 6)
        self.assertEqual(config['shared'], 'Win + control')
        self.assertEqual(keys.chord('CTRL + control + Enter'), 'CTRL + Return')
        self.assertEqual(keys.chord('code:38'), 'code:38')

    def test_rejects_duplicate_chords_and_injection(self):
        config = keys.defaults()
        config['actions']['settings']['key'] = 'control + e'
        with self.assertRaisesRegex(ValueError, 'Duplicate'):
            keys.validate(config)
        config = keys.defaults()
        config['actions']['settings'] = {'shared': True, 'enabled': True, 'key': 'code:38'}
        with self.assertRaisesRegex(ValueError, 'key names consistently'):
            keys.validate(config)
        for value in ('', 'CTRL', 'SUPER +', 'A;exec evil', '";os.execute()', 'A\nB', 'code:0', 'code:256', 'CTRL + A + B'):
            with self.subTest(value=value), self.assertRaises(ValueError):
                keys.chord(value)
        for value in (None, [], {}, {'shared': 'ALT', 'actions': {}}):
            with self.assertRaises(ValueError):
                keys.validate(value)
        config = keys.defaults(); config['actions']['settings']['enabled'] = 1
        with self.assertRaises(ValueError): keys.validate(config)

    def test_file_roundtrip_atomic_private_mode_and_external_edit_detection(self):
        with tempfile.TemporaryDirectory() as tmp:
            file = Path(tmp) / 'prefs/keybindings.lua'
            config = keys.validate(keys.defaults())
            self.assertEqual(keys.read_config(file), config)
            keys.atomic_write(file, keys.render(config))
            self.assertEqual(keys.read_config(file), config)
            self.assertEqual(file.stat().st_mode & 0o777, 0o600)
            file.write_text(file.read_text() + '-- external change\n')
            with self.assertRaisesRegex(ValueError, 'edited externally'): keys.read_config(file)

    def test_preview_apply_never_calls_compositor(self):
        with tempfile.TemporaryDirectory() as tmp, patch.object(keys, 'hypr') as hypr:
            path = Path(tmp) / 'keybindings.lua'
            message = keys.apply(keys.validate(keys.defaults()), path, True)
            self.assertIn('preview only', message)
            hypr.assert_not_called()
            self.assertTrue(path.exists())

    def test_live_apply_checks_registry_and_conflicts_before_writing(self):
        with tempfile.TemporaryDirectory() as tmp, patch.object(keys, 'hypr', side_effect=['ok', '[]', 'ok']) as hypr:
            path = Path(tmp) / 'keybindings.lua'
            keys.apply(keys.validate(keys.defaults()), path, False)
            self.assertEqual(hypr.call_count, 3)
            self.assertIn('assert(_G.pixel_shell_keys', hypr.call_args_list[0].args[0][1])
            self.assertEqual(hypr.call_args_list[1].args[0], ['-j', 'binds'])
            self.assertTrue(path.exists())

    def test_missing_registry_leaves_configuration_untouched(self):
        with tempfile.TemporaryDirectory() as tmp, patch.object(keys, 'hypr', return_value='Activate updated configuration') as hypr:
            file = Path(tmp) / 'keys'; file.write_text('original')
            with self.assertRaisesRegex(RuntimeError, 'Activate'): keys.apply(keys.validate(keys.defaults()), file, False)
            self.assertEqual(file.read_text(), 'original')
            self.assertEqual(hypr.call_count, 1)

    def test_conflicts_rejected_owned_and_other_submap_bindings_ignored(self):
        config = keys.validate(keys.defaults())
        bind = {'key': 'space', 'modmask': 8, 'description': 'Another app'}
        with self.assertRaisesRegex(ValueError, 'already used'): keys.check_conflicts(config, [bind])
        keys.check_conflicts(config, [{**bind, 'description': 'Pixel shell: launcher'}])
        keys.check_conflicts(config, [{**bind, 'submap': 'resize'}])
        with self.assertRaises(ValueError): keys.check_conflicts(config, [{**bind, 'submap': 'resize', 'submap_universal': 'true'}])
        with self.assertRaises(ValueError): keys.check_conflicts(config, [{**bind, 'key': '', 'keycode': 65}])
        with self.assertRaises(ValueError): keys.check_conflicts(config, {})
        with self.assertRaises(ValueError): keys.check_conflicts(config, [{}])

    def test_failed_save_rolls_back_runtime_and_keeps_old_file(self):
        with tempfile.TemporaryDirectory() as tmp, patch.object(keys, 'hypr', side_effect=['ok', '[]', 'ok', 'ok']) as hypr:
            file = Path(tmp) / 'keys'; file.write_text('old')
            with patch.object(keys, 'atomic_write', side_effect=OSError('disk full')), self.assertRaisesRegex(OSError, 'disk full'):
                keys.apply(keys.validate(keys.defaults()), file, False)
            self.assertEqual(file.read_text(), 'old')
            self.assertEqual(hypr.call_args.args[0], ['eval', 'pixel_shell_keys.undo()'])

    def test_failed_compositor_apply_is_rolled_back_without_file_write(self):
        with tempfile.TemporaryDirectory() as tmp, patch.object(keys, 'hypr', side_effect=['ok', '[]', 'bad key', 'ok']) as hypr:
            file = Path(tmp) / 'keys'
            with self.assertRaisesRegex(RuntimeError, 'bad key'): keys.apply(keys.validate(keys.defaults()), file, False)
            self.assertFalse(file.exists())
            self.assertEqual(hypr.call_args.args[0], ['eval', 'pixel_shell_keys.undo()'])

    def test_uncertain_rollback_is_actionable(self):
        with tempfile.TemporaryDirectory() as tmp, patch.object(keys, 'hypr', side_effect=['ok', '[]', 'bad key', 'compositor disappeared']):
            with self.assertRaisesRegex(RuntimeError, 'Restoration could not be confirmed'):
                keys.apply(keys.validate(keys.defaults()), Path(tmp) / 'keys', False)

    def test_cli_preview_persistence_isolated_from_real_config(self):
        with tempfile.TemporaryDirectory() as tmp:
            private = Path(tmp) / 'private'; live = Path(tmp) / 'live'; live.mkdir()
            marker = live / 'keybindings.lua'; marker.write_text('unchanged')
            env = {**os.environ, 'PIXEL_SHELL_PREVIEW': '1', 'XDG_CONFIG_HOME': str(private), 'PIXEL_SHELL_LIVE_CONFIG': str(live)}
            result = subprocess.run(['python3', str(ROOT / 'scripts/shell-keybindings.py'), 'apply', json.dumps(keys.defaults())], env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn('preview only', json.loads(result.stdout)['message'])
            self.assertTrue((private / 'pixel-shell/keybindings.lua').exists())
            self.assertEqual(marker.read_text(), 'unchanged')

    def test_live_conflict_preserves_file_and_does_not_apply(self):
        binds = json.dumps([{"modmask": 8, "key": "space", "description": "Other"}])
        with tempfile.TemporaryDirectory() as tmp, patch.object(keys, 'hypr', side_effect=['ok', binds]) as hypr:
            file = Path(tmp) / 'keys'; file.write_text('unchanged')
            with self.assertRaisesRegex(ValueError, 'already used'):
                keys.apply(keys.validate(keys.defaults()), file, False)
            self.assertEqual(hypr.call_count, 2)
            self.assertEqual(file.read_text(), 'unchanged')

    def test_atomic_replace_failure_cleans_temp_and_preserves_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            file = Path(tmp) / 'keys'; file.write_text('unchanged')
            with patch.object(keys.os, 'replace', side_effect=OSError('disk full')), self.assertRaises(OSError):
                keys.atomic_write(file, 'new')
            self.assertEqual(file.read_text(), 'unchanged')
            self.assertEqual(list(Path(tmp).iterdir()), [file])

    def test_managed_symlink_is_not_overwritten(self):
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp) / 'source'; source.write_text('unchanged')
            link = Path(tmp) / 'keys'; link.symlink_to(source)
            with self.assertRaisesRegex(ValueError, 'managed by a symlink'):
                keys.atomic_write(link, 'new')
            self.assertTrue(link.is_symlink())
            self.assertEqual(source.read_text(), 'unchanged')

    def test_lifecycle_and_clock_contracts(self):
        launcher = (ROOT / 'quickshell/launcher/AppLauncherContent.qml').read_text()
        self.assertIn('onApplicationsChanged: selectionRefresh.restart()', launcher)
        for name in ('launcher/AppLauncherContent.qml', 'common/Sheet.qml', 'wallpaper/WallpaperLauncherContent.qml', 'wallpaper/QuickWallpapersContent.qml', 'common/PathPicker.qml', 'bar/PowerMenuContent.qml', 'bar/WifiPanelContent.qml'):
            self.assertNotIn('Qt.callLater', (ROOT / 'quickshell' / name).read_text())
        self.assertIn('active: Settings.ready', (ROOT / 'quickshell/bar/ShellFrame.qml').read_text())
        clock = (ROOT / 'quickshell/bar/BarModule.qml').read_text().split('id: clock\n', 1)[1].split('id: wizard')[0]
        self.assertIn('GridLayout', clock)
        self.assertIn('Layout.alignment: Qt.AlignCenter', clock)
        self.assertIn('root.horizontal ? "HH:mm" : "HH\\nmm"', clock)
        self.assertNotIn('root.horizontal ? 12 : 14', clock)
        self.assertIn('Layout.preferredHeight: 34', clock)
        network = (ROOT / 'quickshell/bar/NetworkEditor.qml').read_text()
        self.assertIn('interval: 7000', network)
        self.assertIn('warningTimeout.restart()', network)
        self.assertIn('onTriggered: root.errorMessage = ""', network)


@unittest.skipUnless(LuaRuntime, 'Install lupa for the inert Lua handle tests')
class LuaShortcutTests(unittest.TestCase):
    def runtime(self, config_path):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.globals().test_config = config_path
        lua.execute('''
            handles = {}; fail_chord = nil
            local getenv = os.getenv
            os.getenv = function(k) if k == "XDG_CONFIG_HOME" then return test_config else return getenv(k) end end
            hl = { dsp = {exec_cmd = function(c) return c end} }
            hl.bind = function(chord, command, opts)
                if chord == fail_chord then error("invalid chord") end
                local h = {chord = chord, command = command, enabled = true, description = opts.description}
                function h:set_enabled(v) self.enabled = v end
                table.insert(handles, h); return h
            end
        ''')
        lua.execute('dofile(' + json.dumps(str(ROOT / 'scripts/shell-keybindings.lua')) + ')')
        return lua

    def test_defaults_replace_owned_handles_undo_and_do_not_touch_unrelated(self):
        with tempfile.TemporaryDirectory() as tmp:
            lua = self.runtime(tmp)
            lua.execute('''
                assert(#pixel_shell_keys.handles == 7)
                unrelated = hl.bind("SUPER + Q", "not-shell", {description="Other"})
                old = pixel_shell_keys.handles
                pixel_shell_keys.apply({{id="settings", chord="SUPER + F8"}})
                assert(#pixel_shell_keys.handles == 1 and pixel_shell_keys.handles[1].enabled)
                assert(pixel_shell_keys.handles[1].command == "qs ipc call settings toggle")
                for _, h in ipairs(old) do assert(not h.enabled) end
                assert(unrelated.enabled)
                pixel_shell_keys.undo()
                assert(pixel_shell_keys.handles == old and unrelated.enabled)
                for _, h in ipairs(old) do assert(h.enabled) end
            ''')

    def test_partial_registration_failure_preserves_old_bindings(self):
        with tempfile.TemporaryDirectory() as tmp:
            lua = self.runtime(tmp)
            lua.execute('''
                old = pixel_shell_keys.handles; fail_chord = "bad"
                local ok = pcall(pixel_shell_keys.apply, {{id="settings",chord="F8"}, {id="power",chord="bad"}})
                assert(not ok and pixel_shell_keys.handles == old)
                for _, h in ipairs(old) do assert(h.enabled) end
                assert(not handles[#handles].enabled)
                pixel_shell_keys.undo()
                for _, h in ipairs(old) do assert(h.enabled) end
            ''')

    def test_saved_config_reloads_and_corrupt_file_falls_back(self):
        with tempfile.TemporaryDirectory() as tmp:
            file = Path(tmp) / 'pixel-shell/keybindings.lua'
            config = keys.defaults(); config['shared'] = 'SUPER'
            keys.atomic_write(file, keys.render(keys.validate(config)))
            lua = self.runtime(tmp)
            self.assertEqual(lua.eval('pixel_shell_keys.handles[1].chord'), 'SUPER + space')
            file.write_text('not valid lua :')
            lua = self.runtime(tmp)
            self.assertEqual(lua.eval('pixel_shell_keys.handles[1].chord'), 'ALT + space')
