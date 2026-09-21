#!/usr/bin/env bash
# One serialized apply transaction. Firefox stays on Wallust, independently of shell recipes.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
selected_path="${1:?usage: apply-wallpaper.sh image [recipe tone saturation source contrast]}"
mapfile -t prefs < <(python3 "$ROOT/scripts/shell-state.py" theme-args)
recipe="${2:-${prefs[0]:-black}}"; tone="${3:-${prefs[1]:-0}}"; saturation="${4:-${prefs[2]:-1}}"
source="${5:-${prefs[3]:-representative}}"; contrast="${6:-${prefs[4]:-0}}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/wallpaper"
mkdir -p "$STATE_DIR"
exec 9>"$STATE_DIR/apply.lock"
flock 9
mode=dark
[[ "$recipe" == paper ]] && mode=light
python3 "$ROOT/scripts/generate-theme.py" "$selected_path" "$mode" "$contrast" \
  --recipe "$recipe" --tone "$tone" --saturation "$saturation" --source "$source"
awww img "$selected_path" --transition-type fade --transition-fps 60 --transition-duration 0.6
printf '%s\n' "$selected_path" > "$STATE_DIR/current.tmp"
mv "$STATE_DIR/current.tmp" "$STATE_DIR/current"
# Update the mascot without needing to wait for the systemd path watcher.
bash "$ROOT/quickshell/bar/scripts/generate-theme-assets.sh" || echo 'Mascot refresh failed' >&2
if wallust run "$selected_path"; then
    pywalfox update || echo 'Firefox reload unavailable; colors are ready for next launch' >&2
else
    notify-send 'Wallpaper' 'Shell updated; Wallust failed. Firefox keeps its previous palette.' || true
fi
# GTK/Qt remain independently managed by Matugen; do not route Firefox through it.
matugen image "$selected_path" -m "$mode" -t scheme-tonal-spot --source-color-index 0 --contrast 0.2 || echo 'GTK/Qt palette update failed' >&2
hyprctl reload || true
# Kitty supports config reload via SIGUSR1. Foot receives Wallust terminal sequences.
pkill -USR1 -x kitty || true
notify-send 'Wallpaper' "Applied $(basename -- "$selected_path") · $recipe" || true
