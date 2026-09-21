#!/usr/bin/env bash
# Cache only; never change Firefox/terminal templates while priming.
set -uo pipefail
python3 - <<'PY'
import json, os, subprocess, tempfile
from pathlib import Path
home = Path.home()
settings = Path(os.environ.get('XDG_CONFIG_HOME', home / '.config')) / 'pixel-shell/settings.json'
try:
    directory = Path(json.loads(settings.read_text()).get('wallpaperDir', str(home / 'Pictures/Wallpapers')))
except (OSError, ValueError):
    directory = home / 'Pictures/Wallpapers'
failed = []
if directory.is_dir():
    for image in sorted(directory.iterdir()):
        if not image.is_file() or image.suffix.lower() not in ('.png', '.jpg', '.jpeg', '.webp'):
            continue
        if subprocess.run(['wallust', 'run', str(image), '--skip-sequences', '--skip-templates']).returncode:
            failed.append(str(image))
output = home / '.cache/wallust/failed_wallpapers.json'
output.parent.mkdir(parents=True, exist_ok=True)
with tempfile.NamedTemporaryFile(mode='w', dir=output.parent, delete=False) as f:
    json.dump(failed, f)
    name = f.name
os.replace(name, output)
print(f'Cache ready: {len(failed)} images failed; no wallpapers deleted.')
PY
