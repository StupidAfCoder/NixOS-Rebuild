"""Helper integration tests replace ALL session-facing commands with temporary stubs."""
import json
import os
from pathlib import Path
import shlex
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class PreviewTests(unittest.TestCase):
    def run_preview(self, active=True, code=0, manual=False, software=False):
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            bin_dir = base / 'bin'
            bin_dir.mkdir()
            config = base / 'original-config/pixel-shell/settings.json'
            config.parent.mkdir(parents=True)
            original = '{"displayName":"Original","trackingEnabled":true,"workspaceAudioEnabled":true}'
            config.write_text(original)
            original_state = base / 'original-state/pixel-shell/usage.json'
            original_state.parent.mkdir(parents=True)
            original_state.write_text('{"days":{"2026-09-21":{"real-app":8}}}')
            state_before = original_state.read_bytes()
            scripts = {
                'python3': '#!/bin/sh\nexec ' + shlex.quote(sys.executable) + ' "$@"\n',
                'systemctl': '''#!/bin/sh
printf '%s\n' "$*" >> "$TEST_TRACE"
case "$*" in *is-active*) exit "$TEST_SERVICE_STATUS";; esac
exit 0
''',
                'pgrep': '#!/bin/sh\nexit "$TEST_MANUAL_STATUS"\n',
                'quickshell': '''#!/bin/sh
printf 'preview=%s config=%s args=%s\n' "$PIXEL_SHELL_PREVIEW" "$XDG_CONFIG_HOME" "$*" >> "$TEST_TRACE"
printf 'root=%s video=%s texture=%s\n' "$PIXEL_SHELL_ROOT" "${QT_FFMPEG_DECODING_HW_DEVICE_TYPES:-auto}" "${QT_DISABLE_HW_TEXTURES_CONVERSION:-auto}" >> "$TEST_TRACE"
exit "$TEST_QS_EXIT"
''',
            }
            for name, text in scripts.items():
                executable = bin_dir / name
                executable.write_text(text)
                executable.chmod(0o700)
            env = {**os.environ, 'PATH': str(bin_dir) + ':' + os.environ['PATH'],
                   'WAYLAND_DISPLAY': 'test-only-no-real-wayland', 'XDG_RUNTIME_DIR': tmp,
                   'XDG_CONFIG_HOME': str(config.parent.parent), 'XDG_STATE_HOME': str(original_state.parent.parent),
                   'TEST_TRACE': str(base / 'trace'), 'TEST_SERVICE_STATUS': '0' if active else '3',
                   'TEST_MANUAL_STATUS': '0' if manual else '1', 'TEST_QS_EXIT': str(code)}
            result = subprocess.run(['bash', str(ROOT / 'scripts/preview-shell.sh'), '--sample-history'] + (['--software-video'] if software else []),
                                    env=env, capture_output=True, text=True, timeout=10)
            self.assertEqual(result.returncode, 1 if manual else code, result.stderr)
            self.assertEqual(config.read_text(), original)
            self.assertEqual(original_state.read_bytes(), state_before)
            preview = next(base.glob('pixel-shell-preview.*'))
            cfg = json.loads((preview / 'config/pixel-shell/settings.json').read_text())
            self.assertEqual(cfg['displayName'], 'Original')
            self.assertFalse(cfg['trackingEnabled'])
            self.assertFalse(cfg['workspaceAudioEnabled'])
            history = json.loads((preview / 'state/pixel-shell/usage.json').read_text())
            self.assertTrue(history['sampleData'])
            self.assertGreater(len(history['days']), 30)
            trace = (base / 'trace').read_text()
            self.assertEqual('--user stop quickshell.service' in trace, active)
            self.assertEqual('--user start quickshell.service' in trace, active)
            self.assertEqual('preview=1' in trace, not manual)
            self.assertTrue((preview / 'cache/quickshell/wizard-idle.png').is_file())
            self.assertTrue((preview / 'cache/quickshell/preview-theme/quickshell/bar/theme/colors.json').is_file())
            self.assertTrue((preview / 'state/pixel-shell/status.json').is_file())
            self.assertTrue((preview / 'state/wallpaper/current').is_file())
            if not manual:
                self.assertIn('root=' + str(ROOT), trace)
                if software:
                    self.assertIn('video=, texture=1', trace)

    def test_restores_service_without_changing_real_preferences_or_history(self):
        self.run_preview()

    def test_restores_service_on_shell_failure(self):
        self.run_preview(code=7)

    def test_does_not_start_previously_inactive_service(self):
        self.run_preview(active=False)

    def test_refuses_manual_duplicate_and_restores_original_service(self):
        self.run_preview(manual=True)

    def test_software_video_option(self):
        self.run_preview(software=True)

    def test_fixture_refuses_overwrite(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'existing.json'
            path.write_text('real history')
            result = subprocess.run([sys.executable, str(ROOT / 'scripts/preview-history.py'), str(path)], capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(path.read_text(), 'real history')


if __name__ == '__main__':
    unittest.main()
