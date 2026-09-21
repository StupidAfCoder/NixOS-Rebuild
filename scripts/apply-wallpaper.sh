#!/usr/bin/env bash
# Serialize applications; prepare colors before touching the live wallpaper or palette.
set -euo pipefail
[[ "${PIXEL_SHELL_PREVIEW:-}" != 1 ]] || { echo "Live wallpaper apply is blocked in preview" >&2; exit 3; }
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
selected_path="${1:?usage: apply-wallpaper.sh image [recipe tone saturation source contrast]}"
mapfile -t prefs < <(python3 "$ROOT/scripts/shell-state.py" theme-args)
recipe="${2:-${prefs[0]:-balanced}}"; tone="${3:-${prefs[1]:-0}}"; saturation="${4:-${prefs[2]:-1}}"
source="${5:-${prefs[3]:-representative}}"; contrast="${6:-${prefs[4]:-0}}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/wallpaper"
mkdir -p "$STATE_DIR"
exec 9>"$STATE_DIR/apply.lock"
flock 9
stage="$(mktemp -d "$STATE_DIR/palette.XXXXXX")"
trap 'rm -rf -- "$stage"' EXIT
mode=dark
[[ "$recipe" == paper ]] && mode=light
# Normalize all pre-apply failures to 1: argparse also uses 2, but our 2 means partial success.
if ! python3 "$ROOT/scripts/generate-theme.py" "$selected_path" "$mode" "$contrast" \
  --recipe "$recipe" --tone "$tone" --saturation "$saturation" --source "$source" --output-dir "$stage"; then
    exit 1
fi
if ! awww img "$selected_path" --transition-type fade --transition-fps 60 --transition-duration 0.6; then
    exit 1
fi
# Each publication is atomic; external desktop tools cannot form a single atomic transaction.
partial=0
publish() {
    local source="$1" target="$2" temporary
    mkdir -p "$(dirname -- "$target")" || return 1
    temporary="$(mktemp "$target.XXXXXX")" || return 1
    if ! cp -- "$source" "$temporary" || ! mv -- "$temporary" "$target"; then
        rm -f -- "$temporary"
        return 1
    fi
}
warn() { partial=2; printf '%s\n' "$1" >&2; }
for file in hypr/colors.lua quickshell/bar/theme/colors.json; do
    publish "$stage/$file" "$ROOT/$file" || warn "Could not publish $file"
done
printf '%s\n' "$selected_path" > "$stage/current"
publish "$stage/current" "$STATE_DIR/current" || warn 'Could not record the active wallpaper'
bash "$ROOT/quickshell/bar/scripts/generate-theme-assets.sh" || warn 'Mascot refresh failed'
bash "$ROOT/scripts/sync-wallust.sh" "$selected_path" || warn 'Live application color sync failed; check Wallust/Pywalfox'
# GTK/Qt remain independently managed by Matugen; Firefox remains on Wallust.
matugen image "$selected_path" -m "$mode" -t scheme-tonal-spot --source-color-index 0 --contrast 0.2 || warn 'GTK/Qt palette update failed'
hyprctl reload || warn 'Compositor theme reload failed'
if [[ "$partial" == 0 ]]; then
    notify-send 'Wallpaper' "Applied $(basename -- "$selected_path") · $recipe" || true
else
    notify-send 'Wallpaper' 'Wallpaper changed; some theme updates failed. Check the shell log.' || true
fi
exit "$partial"
