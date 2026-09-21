import importlib.util
import tempfile
import unittest
from datetime import date
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("state", ROOT / "scripts/shell-state.py")
state = importlib.util.module_from_spec(spec)
spec.loader.exec_module(state)


class StateTests(unittest.TestCase):
    def test_defaults_private(self):
        c = state.validate({})
        self.assertFalse(c["trackingEnabled"])
        self.assertFalse(c["workspaceAudioEnabled"])
        self.assertEqual(c["recipe"], "black")
        self.assertEqual(c["frameWidth"], 6)

    def test_reject_invalid_settings(self):
        for bad in ({"tone": float("nan")}, {"frameWidth": 1}, {"mutedWorkspaces": [-1]}, {"trackingEnabled": "yes"}, {"recipe": "invalid"}, {"saturation": True}):
            with self.assertRaises(ValueError):
                state.validate(bad)

    def test_atomic_private_save(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "settings.json"
            state.save(path, {"name": "a b ' c"})
            self.assertEqual(state.load(path, {}), {"name": "a b ' c"})
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)

    def test_usage_day_buckets_and_retention(self):
        days = {}
        state.add_usage(days, "2026-09-20", "firefox", 2)
        state.add_usage(days, "2026-09-21", "foot", 2)
        state.add_usage(days, "2026-09-21", "foot", 2)
        self.assertEqual(days["2026-09-21"]["foot"], 4)
        self.assertEqual(list(state.prune(days, 1, date(2026, 9, 21))), ["2026-09-21"])
        self.assertNotIn("titles", str(days))

    def test_conservative_pid_mapping(self):
        clients = [{"pid": 20, "workspace": {"id": 1}}]
        self.assertEqual(state.stream_workspace(21, clients, lambda p: 20), 1)
        clients.append({"pid": 20, "workspace": {"id": 2}})
        self.assertIsNone(state.stream_workspace(21, clients, lambda p: 20))
        self.assertIsNone(state.stream_workspace(1, clients))

    def test_audio_restores_only_owned_and_stable_streams(self):
        clients = [{"pid": 20, "workspace": {"id": 1}}]
        def stream(index, serial, muted=False):
            return {"index": index, "mute": muted, "properties": {"application.process.id": "20", "object.serial": serial}}
        streams = [stream(1, "100"), stream(2, "200", True)]
        calls = []
        def command(args, json_output=False):
            if args[0] == "hyprctl":
                return clients
            if args[-1] == "sink-inputs":
                return streams
            calls.append(args)
            return ""
        cfg = {**state.DEFAULTS, "workspaceAudioEnabled": True, "mutedWorkspaces": [1]}
        with patch.object(state, "command", command):
            owned, _ = state.audio_tick(cfg, {})
            self.assertEqual(list(owned), ["1:100:20"])
            self.assertEqual(len(calls), 1)  # pre-existing mute is not owned
            calls.clear()
            state.audio_tick({**cfg, "workspaceAudioEnabled": False}, owned)
            self.assertEqual(calls, [["pactl", "set-sink-input-mute", "1", "0"]])
            calls.clear()
            streams[0] = stream(1, "999")  # same index, different stream
            state.audio_tick({**cfg, "workspaceAudioEnabled": False}, owned)
            self.assertEqual(calls, [])

class ModuleTests(unittest.TestCase):
    def test_defaults_are_complete_and_independent(self):
        first, second = state.validate({}), state.validate({})
        self.assertEqual(len(first['barModules']), 12)
        self.assertTrue(all(first['barModules'].values()))
        first['barModules']['clock'] = False
        self.assertTrue(second['barModules']['clock'])
        self.assertEqual(second['workspaceCount'], 5)

    def test_module_schema(self):
        for invalid in ([], {'unknown': True}, {'clock': 0}, {'clock': 'false'}, None):
            with self.subTest(invalid=invalid), self.assertRaises(ValueError):
                state.validate({'barModules': invalid})
        cfg = state.validate({'barModules': {'wizard': False}})
        self.assertFalse(cfg['barModules']['wizard'])
        self.assertTrue(cfg['barModules']['clock'])
        for invalid in (0, 11, True, '5', float('nan')):
            with self.assertRaises(ValueError):
                state.validate({'workspaceCount': invalid})

    def test_cli_partial_merge_and_restart(self):
        import os
        import subprocess
        import sys
        with tempfile.TemporaryDirectory() as tmp:
            env = {**os.environ, 'XDG_CONFIG_HOME': tmp}
            cli = [sys.executable, str(ROOT / 'scripts/shell-state.py')]
            for payload in ('{"barModules":{"clock":false}}', '{"barModules":{"wizard":false},"workspaceCount":8}'):
                subprocess.run([*cli, 'patch', payload], env=env, check=True, capture_output=True)
            subprocess.run([*cli, 'init'], env=env, check=True, capture_output=True)
            cfg = state.load(Path(tmp) / 'pixel-shell/settings.json', {})
            self.assertFalse(cfg['barModules']['clock'])
            self.assertFalse(cfg['barModules']['wizard'])
            self.assertTrue(cfg['barModules']['launcher'])
            self.assertEqual(cfg['workspaceCount'], 8)
            original = cfg.copy()
            result = subprocess.run([*cli, 'patch', '{"barModules":{"clock":1}}'], env=env, capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(original, state.load(Path(tmp) / 'pixel-shell/settings.json', {}))

    def test_concurrent_patches_do_not_drop_modules(self):
        import json
        import os
        import subprocess
        import sys
        with tempfile.TemporaryDirectory() as tmp:
            env = {**os.environ, 'XDG_CONFIG_HOME': tmp}
            processes = [subprocess.Popen([sys.executable, str(ROOT / 'scripts/shell-state.py'), 'patch',
                         json.dumps({'barModules': {key: False}})], env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                         for key in state.BAR_MODULES]
            for proc in processes:
                _, error = proc.communicate(timeout=10)
                self.assertEqual(proc.returncode, 0, error)
            cfg = state.load(Path(tmp) / 'pixel-shell/settings.json', {})
            self.assertFalse(any(cfg['barModules'].values()))

    def test_corrupt_history_pruning_and_recorded_zero(self):
        days = {'bad-date': {'firefox': 4}, '2026-02-30': {}, '2026-9-20': {},
                '2026-09-22': {}, '2026-09-19': [], '2026-09-20': {},
                '2026-09-21': {'foot': 42, 'bad': '3', 'huge': 90000, 'nan': float('nan'),
                               'bool': True, '__proto__': 4, 'negative': -1}}
        self.assertEqual(state.prune(days, 30, date(2026, 9, 21)),
                         {'2026-09-20': {}, '2026-09-21': {'foot': 42}})
        self.assertEqual(state.prune([], 30), {})


if __name__ == "__main__":
    unittest.main()
