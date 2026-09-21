"""No desktop commands run: temporary HOME and stubs for Wallust/Pywalfox/Kitty."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class WallustSyncTests(unittest.TestCase):
    def run_sync(self, preview=False, confirmed=False, fail=False, malformed=False):
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            image = home / 'scene with spaces.png'
            image.write_bytes(b'stub image')
            bin_dir = home / 'bin'
            bin_dir.mkdir()
            scripts = {
                'wallust': '''#!/usr/bin/env python3
import json, os, pathlib, sys
home = pathlib.Path(os.environ['HOME'])
with (home/'trace').open('a') as f:
    f.write(json.dumps({'cmd':sys.argv,'cache':os.environ['XDG_CACHE_HOME'],'config':os.environ['XDG_CONFIG_HOME']})+'\\n')
if os.environ.get('FAIL') == '1': sys.exit(1)
data = {'wallpaper':sys.argv[-1], 'special':dict.fromkeys(['background','foreground','cursor'],'#aabbcc'), 'colors':{f'color{i}':'#aabbcc' for i in range(16)}}
p = home/'.cache/wal/colors.json'; p.parent.mkdir(parents=True,exist_ok=True)
p.write_text('invalid' if os.environ.get('MALFORMED') == '1' else json.dumps(data))
''',
                'pywalfox': '#!/bin/sh\nprintf "pywalfox %s\\n" "$*" >> "$HOME/trace"\n',
                'pkill': '#!/bin/sh\nprintf "kitty refresh\\n" >> "$HOME/trace"\n',
            }
            for name, source in scripts.items():
                file = bin_dir / name
                file.write_text(source)
                file.chmod(0o700)
            env = {**os.environ, 'HOME':tmp, 'PATH':str(bin_dir)+':'+os.environ['PATH'],
                   'XDG_CONFIG_HOME':str(home/'private-config'), 'XDG_CACHE_HOME':str(home/'private-cache'),
                   'PIXEL_SHELL_PREVIEW':'1' if preview else '0',
                   'PIXEL_SHELL_LIVE_CONFIG':str(home/'live-config'), 'PIXEL_SHELL_LIVE_CACHE':str(home/'live-cache'),
                   'PIXEL_SHELL_LIVE_STATE':str(home/'live-state'), 'FAIL':'1' if fail else '0', 'MALFORMED':'1' if malformed else '0'}
            result = subprocess.run(['bash',str(ROOT/'scripts/sync-wallust.sh'),str(image)]+(['--live-from-preview'] if confirmed else []), env=env, capture_output=True, text=True)
            trace = (home/'trace').read_text() if (home/'trace').exists() else ''
            if preview and not confirmed:
                self.assertEqual(result.returncode,3)
                self.assertEqual(trace,'')
                return
            if fail or malformed:
                self.assertNotEqual(result.returncode,0)
                self.assertNotIn('pywalfox update',trace)
                return
            self.assertEqual(result.returncode,0,result.stderr)
            entry=json.loads(trace.splitlines()[0])
            self.assertEqual(entry['cmd'][1:4],['--config-dir',str(ROOT/'wallust'),'run'])
            expected='live' if preview else 'private'
            self.assertEqual(entry['cache'],str(home/f'{expected}-cache'))
            self.assertEqual(entry['config'],str(home/f'{expected}-config'))
            self.assertEqual(json.loads((home/f'{expected}-cache/wal/colors.json').read_text())['wallpaper'],str(image))
            self.assertIn('pywalfox update',trace)
            if preview:
                self.assertFalse((home/'private-cache/wal/colors.json').exists())

    def test_normal_live_sync(self): self.run_sync()
    def test_preview_is_blocked_by_default(self): self.run_sync(preview=True)
    def test_explicit_preview_sync_uses_original_environment(self): self.run_sync(preview=True,confirmed=True)
    def test_wallust_failure_does_not_reload_stale_colors(self): self.run_sync(fail=True)
    def test_malformed_cache_does_not_reload(self): self.run_sync(malformed=True)

    def test_live_apply_is_blocked_in_preview(self):
        result = subprocess.run(['bash',str(ROOT/'scripts/apply-wallpaper.sh'),'ignored'],env={**os.environ,'PIXEL_SHELL_PREVIEW':'1'},capture_output=True)
        self.assertEqual(result.returncode,3)
