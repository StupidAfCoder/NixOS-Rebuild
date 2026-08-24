#!/usr/bin/env bash
# Applies a wallpaper by path and reruns the retheme pipeline.
# Shared by wallpaper-select.sh (fuzzel path) and WallpaperBackend.qml
# (the Quickshell grid) -- same logic, two different pickers.
set -euo pipefail

selected_path="${1:?usage: apply-wallpaper.sh <path>}"
STATE_DIR="$HOME/.local/state/wallpaper"
MODE_FILE="$HOME/.local/state/theme-mode/current"

mkdir -p "$STATE_DIR" "$(dirname "$MODE_FILE")"
[ -f "$MODE_FILE" ] || echo "dark" > "$MODE_FILE"
mode="$(cat "$MODE_FILE")"

awww img "$selected_path" \
    --transition-type grow \
    --transition-pos "$(hyprctl cursorpos)" \
    --transition-fps 60 \
    --transition-duration 3

echo "$selected_path" > "$STATE_DIR/current"

python3 ~/.nixos_dotfiles/scripts/generate-theme.py "$selected_path" "$mode"
wallust run "$selected_path"
matugen image "$selected_path" -m "$mode" -t scheme-vibrant --source-color-index 0 --contrast 0.2
hyprctl reload
pywalfox update
killall -SIGUSR1 zsh

notify-send "Wallpaper" "Switched to $(basename "$selected_path")"