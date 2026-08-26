#!/usr/bin/env bash
set -uo pipefail   # dropped -e on purpose: we need to inspect wallust's exit code ourselves

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
FAILED_LOG="$HOME/.cache/wallust/failed_wallpapers.json"

mkdir -p "$(dirname "$FAILED_LOG")"

failed=()

for img in "$WALLPAPER_DIR"/*; do
    name="$(basename "$img")"
    echo "Priming cache: $name"
    if wallust run "$img" --skip-sequences --skip-templates; then
        :
    else
        echo "  -> could not generate a palette, flagging and continuing"
        failed+=("$img")
    fi
done

# Write the failed paths as a JSON array so Quickshell can read it directly.
{
    printf '['
    for i in "${!failed[@]}"; do
        [[ $i -gt 0 ]] && printf ','
        printf '"%s"' "${failed[$i]//\"/\\\"}"
    done
    printf ']'
} > "$FAILED_LOG"

echo "Done. ${#failed[@]} wallpaper(s) failed to generate a palette."
