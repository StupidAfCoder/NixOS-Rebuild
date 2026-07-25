#!/usr/bin/env bash
set -euo pipefail

MODE_FILE="$HOME/.local/state/theme-mode/current"
WALL_STATE="$HOME/.local/state/wallpaper/current"
mkdir -p "$(dirname "$MODE_FILE")"
[ -f "$MODE_FILE" ] || echo "dark" > "$MODE_FILE"
[ -f "$WALL_STATE" ] || { notify-send "Theme" "No wallpaper set yet"; exit 1; }

current="$(cat "$MODE_FILE")"
new="dark"; [ "$current" = "dark" ] && new="light"
echo "$new" > "$MODE_FILE"

wallpaper="$(cat "$WALL_STATE")"
python3 ~/.nixos_dotfiles/scripts/generate-theme.py "$wallpaper" "$new"
wallust run "$wallpaper"
notify-send "Theme" "Switched to $new mode"