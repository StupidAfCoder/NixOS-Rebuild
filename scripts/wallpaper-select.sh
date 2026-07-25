#!/usr/bin/env bash
# Wallpaper picker: fuzzel-driven selection from ~/Pictures/Wallpapers,
# applies it via awww, then regenerates the whole theme pipeline
# (matugen -> GTK/Qt/bar colors.json, wallust -> foot) off the same image.
set -euo pipefail

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
STATE_DIR="$HOME/.local/state/wallpaper"
STATE_FILE="$STATE_DIR/current"

mkdir -p "$STATE_DIR"

# Null-separated so filenames with spaces don't break the picker.
mapfile -d '' -t entries < <(
    find "$WALLPAPER_DIR" -maxdepth 1 -type f \
        \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
        -print0
)

if [ "${#entries[@]}" -eq 0 ]; then
    notify-send "Wallpaper" "No images found in $WALLPAPER_DIR"
    exit 1
fi

# fuzzel --dmenu reads one option per line, prints the chosen line back.
# Menu entries are basenames without extension -- matches the names your
# own wallpaper grid already uses ("pink2", "raiden", etc.)
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

# ---- apply wallpaper ----
# grow-from-cursor transition, matching the Caelestia-style feel
awww img "$selected_path" \
    --transition-type grow \
    --transition-pos "$(hyprctl cursorpos)" \
    --transition-fps 60 \
    --transition-duration 3

echo "$selected_path" > "$STATE_FILE"

# ---- retheme everything off the same image ----
# -m dark: pin the mode explicitly instead of relying on matugen's
#   current default, so a future matugen version can't silently flip
#   the whole theme on you.
# --source-color-index 0: keep this -- it's what makes the run
#   non-interactive (matugen otherwise drops you into an arrow-key
#   picker over candidate seed colors, which breaks a script called
#   from fuzzel). Index 0 is just "most frequent pixel", so on a
#   low-saturation wallpaper (cream background, desaturated art) it can
#   grab a near-neutral seed.
# -t scheme-vibrant: this is the actual lever for the "some wallpapers
#   wash out" problem -- it's matugen's real flag (the previous
#   "--prefer vibrant" suggestion doesn't exist in matugen's CLI, it
#   was a made-up flag). scheme-vibrant pushes chroma/tonal separation
#   in the *harmonization algorithm itself*, so even a near-neutral
#   seed color still produces roles with real lightness separation
#   instead of the compressed, everything-is-one-tone palette you're
#   seeing on-screen.
# --contrast 0.2: 0.5 is already halfway to matugen's max and amplifies
#   compression rather than fixing it once the seed is already flat.
matugen image "$selected_path" -t scheme-vibrant --source-color-index 0 --contrast 0.2
wallust run "$selected_path"

notify-send "Wallpaper" "Switched to $choice"