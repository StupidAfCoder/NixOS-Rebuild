"""Run the real apply script and palette generator in a COPY, with all desktop tools stubbed."""
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys
import tempfile
import unittest
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


class ApplyTests(unittest.TestCase):
    def run_apply(self, failure='', recipe='wallpaper'):
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            repo = home / 'checkout with spaces'
            scripts = repo / 'scripts'
            scripts.mkdir(parents=True)
            for name in ('apply-wallpaper.sh','generate-theme.py'):
                shutil.copy(ROOT/'scripts'/name,scripts/name)
            (scripts/'shell-state.py').write_text("print('wallpaper\\n0\\n1\\nrepresentative\\n0')")
            for relative, event in [('scripts/sync-wallust.sh','wallust'),('quickshell/bar/scripts/generate-theme-assets.sh','mascot')]:
                f=repo/relative;f.parent.mkdir(parents=True,exist_ok=True)
                f.write_text(f'#!/bin/sh\necho {event} >> "$TRACE"\n[ "$FAIL" != {event} ]\n')
            theme=repo/'quickshell/bar/theme/colors.json';theme.parent.mkdir(parents=True)
            lua=repo/'hypr/colors.lua';lua.parent.mkdir(parents=True)
            theme.write_text('old palette');lua.write_text('old compositor colors')
            state=home/'state/wallpaper';state.mkdir(parents=True)
            current=state/'current';current.write_text('/old/wallpaper.png\n')
            image=home/'new wallpaper.png';Image.new('RGB',(20,20),(20,80,200)).save(image)
            bin_dir=home/'bin';bin_dir.mkdir()
            wrapper=bin_dir/'python3';wrapper.write_text('#!/bin/sh\nexec '+shlex.quote(sys.executable)+' "$@"\n');wrapper.chmod(0o700)
            for tool in ('awww','matugen','hyprctl','notify-send'):
                f=bin_dir/tool
                f.write_text('''#!/usr/bin/env python3
import os, pathlib, sys
name=pathlib.Path(sys.argv[0]).name
with open(os.environ['TRACE'],'a') as stream: stream.write(name+'\\n')
if name=='awww':
    # Palette must still be untouched at the point the wallpaper daemon is called.
    assert pathlib.Path(os.environ['THEME']).read_text()=='old palette'
sys.exit(1 if os.environ['FAIL']==name else 0)
''');f.chmod(0o700)
            trace=home/'trace'
            env={**os.environ,'HOME':str(home),'XDG_STATE_HOME':str(home/'state'),
                 'PIXEL_SHELL_PREVIEW':'0','PATH':str(bin_dir)+':'+os.environ['PATH'],
                 'TRACE':str(trace),'THEME':str(theme),'FAIL':failure}
            result=subprocess.run(['bash',str(scripts/'apply-wallpaper.sh'),str(image),recipe],env=env,capture_output=True,text=True)
            events=trace.read_text().splitlines() if trace.exists() else []
            self.assertEqual(list(state.glob('palette.*')),[],'staging directory leaked')
            if failure=='awww' or recipe=='invalid':
                self.assertEqual(result.returncode,1,result.stderr)
                self.assertEqual(theme.read_text(),'old palette')
                self.assertEqual(lua.read_text(),'old compositor colors')
                self.assertEqual(current.read_text(),'/old/wallpaper.png\n')
                self.assertEqual(events,['awww'] if failure=='awww' else [])
            else:
                self.assertEqual(result.returncode,2 if failure else 0,result.stderr)
                self.assertEqual(json.loads(theme.read_text())['_meta']['recipe'],recipe)
                self.assertIn('active_border',lua.read_text())
                self.assertEqual(current.read_text().strip(),str(image))
                self.assertEqual(events,['awww','mascot','wallust','matugen','hyprctl','notify-send'])

    def test_success_publishes_only_after_wallpaper_change(self): self.run_apply()
    def test_daemon_failure_preserves_previous_palette_and_state(self): self.run_apply(failure='awww')
    def test_invalid_recipe_is_not_reported_as_partial_success(self): self.run_apply(recipe='invalid')
    def test_followup_failures_report_partial_success(self):
        for step in ('wallust','matugen','mascot','hyprctl'):
            with self.subTest(step=step): self.run_apply(failure=step)
