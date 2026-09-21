#!/usr/bin/env bash
# Toggle the same persisted recipes used by the live wallpaper picker.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/wallpaper/current"
[[ -f "$STATE" ]] || { notify-send Theme 'Choose a wallpaper first'; exit 1; }
mapfile -t prefs < <(python3 "$ROOT/scripts/shell-state.py" theme-args)
recipe=paper
[[ "${prefs[0]}" == paper ]] && recipe=black
bash "$ROOT/scripts/apply-wallpaper.sh" "$(cat "$STATE")" "$recipe" "${prefs[1]}" "${prefs[2]}" "${prefs[3]}" "${prefs[4]}"
python3 "$ROOT/scripts/shell-state.py" patch "{\"recipe\":\"$recipe\"}"
