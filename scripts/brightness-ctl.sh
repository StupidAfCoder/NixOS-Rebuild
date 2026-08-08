#!/usr/bin/env bash
set -euo pipefail

# override with `env OSD_DDCUTIL_DISPLAY=2 ...` if you ever have multiple
# DDC-capable monitors and need a specific one
DDCUTIL_DISPLAY="${OSD_DDCUTIL_DISPLAY:-1}"

has_backlight() {
    [ -n "$(ls -A /sys/class/backlight 2>/dev/null)" ]
}

case "${1:-}" in
    get)
        if has_backlight; then
            brightnessctl -c backlight -m | grep -oP '\d+(?=%)'
        else
            ddcutil getvcp 10 --brief --display "$DDCUTIL_DISPLAY" \
                | awk '{ printf "%d\n", ($4/$5)*100 }'
        fi
        ;;
    set)
        pct="${2:?usage: brightness-ctl.sh set <0-100>}"
        if has_backlight; then
            brightnessctl -c backlight set "${pct}%" >/dev/null
        else
            ddcutil setvcp 10 --display "$DDCUTIL_DISPLAY" "$pct" >/dev/null
        fi
        ;;
    *)
        echo "usage: $0 {get|set <0-100>}" >&2
        exit 1
        ;;
esac