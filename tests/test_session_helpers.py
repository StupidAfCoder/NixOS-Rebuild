"""Desktop-facing helpers tested only with inert mocks; no real session calls."""
import contextlib
import importlib.util
import io
import os
from pathlib import Path
import subprocess
import unittest
from unittest.mock import patch, Mock

ROOT = Path(__file__).resolve().parents[1]


def load(name):
    spec = importlib.util.spec_from_file_location(name, ROOT / "scripts" / (name + ".py"))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


blur = load("preview-blur")
editor = load("network-editor")
TOKEN = "0123456789abcdef01234567"


class SessionHelperTests(unittest.TestCase):
    def test_blur_scopes_rule_to_unique_namespace_without_changing_global_blur(self):
        with patch.object(blur, "run", side_effect=['{"int":1}', 'ok']) as run:
            blur.set_rule(TOKEN, True)
        self.assertEqual(run.call_args_list[0].args[0], ["-j", "getoption", "decoration:blur:enabled"])
        cmd, code = run.call_args_list[1].args[0]
        self.assertEqual(cmd, "eval")
        self.assertIn('namespace = "^quickshell:preview-blur-' + TOKEN + '$"', code)
        self.assertIn('ignore_alpha = 0.2', code)
        self.assertNotIn('hl.config', code)
        self.assertNotIn('exec_cmd', code)

    def test_blur_accepts_current_lua_boolean_option(self):
        with patch.object(blur, "run", side_effect=['{"bool":true}', 'ok']) as run:
            blur.set_rule(TOKEN, True)
        self.assertEqual(run.call_count, 2)

    def test_blur_cleanup_does_not_require_global_blur_or_touch_other_rules(self):
        with patch.object(blur, "run", return_value="ok") as run:
            blur.set_rule(TOKEN, False)
        self.assertEqual(run.call_count, 1)
        code = run.call_args.args[0][1]
        self.assertIn('pixel_shell_preview_blur_' + TOKEN, code)
        self.assertIn(':set_enabled(false)', code)
        self.assertIn('= nil', code)
        self.assertNotIn('hl.layer_rule', code)

    def test_blur_refuses_bad_tokens_disabled_blur_and_unacknowledged_changes(self):
        for token in ('', '../file', '";bad()', 'a' * 23, 'g' * 24):
            with patch.object(blur, "run") as run, self.assertRaises(ValueError):
                blur.set_rule(token, True)
            run.assert_not_called()
        for option in ('{"int":0}', '{"bool":false}', '{"bool":"true"}', '{"bool":false,"int":1}', '{}'):
            with self.subTest(option=option), patch.object(blur, "run", return_value=option) as run, self.assertRaisesRegex(RuntimeError, 'disabled'):
                blur.set_rule(TOKEN, True)
            self.assertEqual(run.call_count, 1)
        with patch.object(blur, "run", side_effect=['{"int":1}', 'Lua error']), self.assertRaisesRegex(RuntimeError, 'Lua error'):
            blur.set_rule(TOKEN, True)

    def test_hyprctl_failures_are_not_reported_as_success(self):
        result = subprocess.CompletedProcess([], 1, '', 'no compositor')
        with patch.object(blur.subprocess, 'run', return_value=result), self.assertRaisesRegex(RuntimeError, 'no compositor'):
            blur.run(['eval', 'code'])

    def test_missing_editor_reports_package_and_supports_ethernet(self):
        err, out = io.StringIO(), io.StringIO()
        with patch.object(editor.shutil, 'which', return_value=None), patch.object(editor.subprocess, 'Popen') as spawn, contextlib.redirect_stderr(err), contextlib.redirect_stdout(out):
            self.assertEqual(editor.main(), 127)
        spawn.assert_not_called()
        self.assertIn('networkmanagerapplet', err.getvalue())
        self.assertIn('Ethernet', err.getvalue())
        self.assertEqual(out.getvalue(), '')

    def test_editor_announces_start_after_spawn_and_restores_live_xdg_only_for_child(self):
        out = io.StringIO()
        env = {'PIXEL_SHELL_PREVIEW':'1', 'PIXEL_SHELL_LIVE_CONFIG':'/live-config', 'PIXEL_SHELL_LIVE_CACHE':'/live-cache', 'PIXEL_SHELL_LIVE_STATE':'/live-state', 'XDG_CONFIG_HOME':'/private'}
        child = Mock(); child.wait.return_value = 0
        with patch.dict(os.environ, env, clear=True), patch.object(editor.shutil, 'which', return_value='/tools/nm-connection-editor'), patch.object(editor.subprocess, 'Popen', return_value=child) as spawn, contextlib.redirect_stdout(out):
            self.assertEqual(editor.main(), 0)
            self.assertEqual(os.environ['XDG_CONFIG_HOME'], '/private')
        self.assertEqual(spawn.call_args.args[0], ['/tools/nm-connection-editor'])
        self.assertEqual(spawn.call_args.kwargs['env']['XDG_CONFIG_HOME'], '/live-config')
        self.assertEqual(spawn.call_args.kwargs['stdout'], subprocess.DEVNULL)
        self.assertEqual(out.getvalue(), 'started\n')

    def test_editor_spawn_and_exit_failures_are_observable(self):
        out, err = io.StringIO(), io.StringIO()
        with patch.object(editor.shutil, 'which', return_value='/editor'), patch.object(editor.subprocess, 'Popen', side_effect=OSError('missing library')), contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            self.assertEqual(editor.main(), 1)
        self.assertEqual(out.getvalue(), '')
        self.assertIn('missing library', err.getvalue())
        child = Mock(); child.wait.return_value = 3
        with patch.object(editor.shutil, 'which', return_value='/editor'), patch.object(editor.subprocess, 'Popen', return_value=child), contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(editor.main(), 3)
