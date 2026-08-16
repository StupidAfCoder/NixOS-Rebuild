#!/usr/bin/env bash
set -uo pipefail   # dropped -e: a failed attempt inside the retry loop shouldn't kill the script

DDCUTIL_DISPLAY="${OSD_DDCUTIL_DISPLAY:-1}"

has_backlight() {
    [ -n "$(ls -A /sys/class/backlight 2>/dev/null)" ]
}

ddc_get() {
    for attempt in 1 2 3; do
        out="$(ddcutil getvcp 10 --brief --display "$DDCUTIL_DISPLAY" 2>/dev/null)"
        if [ -n "$out" ]; then
            echo "$out" | awk '{ printf "%d\n", ($4/$5)*100 }'
            return 0
        fi
        sleep 0.3
    done
    return 1
}

ddc_set() {
    local pct="$1"
    for attempt in 1 2 3; do
        if ddcutil setvcp 10 --display "$DDCUTIL_DISPLAY" "$pct" >/dev/null 2>&1; then
            return 0
        fi
        sleep 0.3
    done
    return 1
}

case "${1:-}" in
    get)
        if has_backlight; then
            brightnessctl -c backlight -m | grep -oP '\d+(?=%)'
        else
            ddc_get
        fi
        ;;
    set)
        pct="${2:?usage: brightness-ctl.sh set <0-100>}"
        if has_backlight; then
            brightnessctl -c backlight set "${pct}%" >/dev/null
        else
            ddc_set "$pct"
        fi
        ;;
    *)
        echo "usage: $0 {get|set <0-100>}" >&2
        exit 1
        ;;
esac