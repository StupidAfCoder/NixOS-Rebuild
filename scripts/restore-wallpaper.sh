#!/usr/bin/env bash
set -euo pipefail
STATE_FILE="$HOME/.local/state/wallpaper/current"

[ -f "$STATE_FILE" ] || exit 0
wallpaper="$(cat "$STATE_FILE")"
[ -f "$wallpaper" ] || exit 0

# Wait for awww-daemon's socket to come up -- it's spawned right before
# this in autostart, give it up to 5s rather than racing it.
for _ in $(seq 1 25); do
    awww query &>/dev/null && break
    sleep 0.2
done

awww img "$wallpaper" --transition-type center