#!/usr/bin/env bash
# Regenerates every themed bar asset from its template + the current
# theme colors. Run this any time colors.json changes -- either by hand
# for now, or automatically via the systemd path unit set up below.
#
# Add a new line here every time you add a new theme-reactive asset --
# this file is the single list of "everything that needs recoloring."

set -euo pipefail

BAR_DIR="$HOME/.nixos_dotfiles/quickshell/bar"
SCRIPTS="$BAR_DIR/scripts"
ASSETS="$BAR_DIR/assets"
THEME="$BAR_DIR/theme/colors.json"
CACHE="$HOME/.cache/quickshell"

mkdir -p "$CACHE"

python3 "$SCRIPTS/recolor_asset.py" \
    "$ASSETS/wizard-template.png" \
    "$CACHE/wizard-idle.png" \
    "$THEME"

# When you make the hover animation sprite sheet, add it here the same way:
# python3 "$SCRIPTS/recolor_asset.py" \
#     "$ASSETS/anim/launcher-hover-template.png" \
#     "$CACHE/launcher-hover-spritesheet.png" \
#     "$THEME"

echo "theme assets regenerated"
