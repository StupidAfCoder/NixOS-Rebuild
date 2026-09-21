#!/usr/bin/env bash
# Regenerate live application templates. Preview callers must explicitly opt in.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
image="${1:?usage: sync-wallust.sh image [--live-from-preview]}"
[[ -f "$image" ]] || { echo 'Wallpaper file not found' >&2; exit 1; }
if [[ "${PIXEL_SHELL_PREVIEW:-}" == 1 ]]; then
    [[ "${2:-}" == --live-from-preview ]] || { echo 'Live app colors are blocked in preview without explicit confirmation' >&2; exit 3; }
    export XDG_CONFIG_HOME="${PIXEL_SHELL_LIVE_CONFIG:?Preview did not supply original config path}"
    export XDG_CACHE_HOME="${PIXEL_SHELL_LIVE_CACHE:?Preview did not supply original cache path}"
    export XDG_STATE_HOME="${PIXEL_SHELL_LIVE_STATE:?Preview did not supply original state path}"
fi
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
mkdir -p "$XDG_CACHE_HOME/wallust"
exec 8>"$XDG_CACHE_HOME/wallust/pixel-shell-sync.lock"
flock 8
# Do not rely on the caller's current directory, config symlink, or preview XDG tree.
wallust --config-dir "$ROOT/wallust" run "$image"
# Wallust's existing template targets ~/.cache/wal; Pywalfox reads XDG_CACHE_HOME.
# Validate before requesting a reload, then mirror atomically for non-default XDG paths.
python3 - "$image" <<'PY'
import json, os, re, sys, tempfile
from pathlib import Path
source = Path.home() / '.cache/wal/colors.json'
data = json.loads(source.read_text())
assert Path(data['wallpaper']).resolve() == Path(sys.argv[1]).resolve(), 'Wallust cache is stale'
for color in [data['special'][k] for k in ('background', 'foreground', 'cursor')] + [data['colors'][f'color{i}'] for i in range(16)]:
    assert re.fullmatch(r'#[0-9a-fA-F]{6}', color), 'Invalid Wallust color cache'
target = Path(os.environ['XDG_CACHE_HOME']) / 'wal/colors.json'
if target != source:
    target.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode='w', dir=target.parent, delete=False) as stream:
        json.dump(data, stream)
        name = stream.name
    os.replace(name, target)
PY
pywalfox update
pkill -USR1 -x kitty || true
printf '%s\n' 'Wallust templates written; Firefox refresh requested. The Pywalfox extension must be enabled and connected.'
