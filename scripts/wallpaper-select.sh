#!/usr/bin/env bash
# Fuzzel-driven picker only -- apply + retheme now lives in apply-wallpaper.sh.
set -euo pipefail

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

mapfile -d '' -t entries < <(
    find "$WALLPAPER_DIR" -maxdepth 1 -type f \
        \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
        -print0
)

if [ "${#entries[@]}" -eq 0 ]; then
    notify-send "Wallpaper" "No images found in $WALLPAPER_DIR"
    exit 1
fi

declare -A name_to_path
menu=""
for path in "${entries[@]}"; do
    name="$(basename "$path")"
    name="${name%.*}"
    name_to_path["$name"]="$path"
    menu+="$name"$'\n'
done

choice="$(printf '%s' "$menu" | fuzzel --dmenu --prompt "Wallpaper> ")" || exit 0
[ -z "$choice" ] && exit 0

selected_path="${name_to_path[$choice]:-}"
if [ -z "$selected_path" ]; then
    notify-send "Wallpaper" "No match for '$choice'"
    exit 1
fi

bash "$(dirname "$0")/apply-wallpaper.sh" "$selected_path"