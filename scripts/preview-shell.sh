#!/usr/bin/env bash
# Run this checkout without replacing ~/.config/quickshell or applying a Nix generation.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ "${1:-}" == --help ]]; then
    echo 'usage: preview-shell.sh [--sample-history]'
    echo 'Temporarily stops the quickshell user service; restores it when preview exits.'
    echo 'Uses private temporary settings/history/cache. Power, wallpaper apply and Trash are disabled.'
    echo 'App launches, network, Bluetooth and audio controls still use the real session.'
    exit 0
fi
[[ $# -eq 0 || ( $# -eq 1 && "$1" == --sample-history ) ]] || { echo 'Unknown option; use --help' >&2; exit 2; }
[[ -n "${WAYLAND_DISPLAY:-}" ]] || { echo 'Run this from a terminal in your Wayland desktop.' >&2; exit 1; }
QS="$(command -v quickshell || command -v qs || true)"
[[ -n "$QS" ]] || { echo 'Quickshell must already be installed.' >&2; exit 1; }
command -v python3 >/dev/null
python3 -c 'from PIL import Image; from materialyoucolor.hct import Hct' || {
    echo 'Use your configured Python with Pillow and materialyoucolor.' >&2; exit 1;
}
preview="$(mktemp -d "${XDG_RUNTIME_DIR:-/tmp}/pixel-shell-preview.XXXXXX")"
# Preserve your avatar/video/path preferences, but never record or control workspace streams here.
original_config="${XDG_CONFIG_HOME:-$HOME/.config}/pixel-shell/settings.json"
mkdir -p "$preview/config/pixel-shell" "$preview/state/pixel-shell" "$preview/cache"
[[ ! -f "$original_config" ]] || cp -- "$original_config" "$preview/config/pixel-shell/settings.json"
export XDG_CONFIG_HOME="$preview/config" XDG_STATE_HOME="$preview/state" XDG_CACHE_HOME="$preview/cache"
export PIXEL_SHELL_PREVIEW=1
python3 "$ROOT/scripts/shell-state.py" patch '{"trackingEnabled":false,"workspaceAudioEnabled":false}'
if [[ "${1:-}" == --sample-history ]]; then
    python3 "$ROOT/scripts/preview-history.py" "$preview/state/pixel-shell/usage.json"
fi
restore=0
child=""
cleanup() {
    code=$?
    trap - EXIT INT TERM
    if [[ -n "$child" ]] && kill -0 "$child" 2>/dev/null; then
        kill "$child" 2>/dev/null || true
        wait "$child" 2>/dev/null || true
    fi
    if [[ "$restore" == 1 ]]; then systemctl --user start quickshell.service || echo 'Restart your original quickshell service manually.' >&2; fi
    printf '\nPreview ended. Logs and temporary preferences: %s\n' "$preview"
    exit "$code"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
if systemctl --user is-active --quiet quickshell.service; then
    restore=1
    systemctl --user stop quickshell.service
fi
if pgrep -u "$UID" -x 'quickshell|qs' >/dev/null; then
    echo 'Another manually started Quickshell is running. Close it yourself, then retry.' >&2
    exit 1
fi
printf 'Native preview: %s\nCtrl+C here to exit and restore your original service.\n' "$ROOT"
printf 'Open from another terminal: qs ipc --path %q call settings toggle\n' "$ROOT/quickshell/shell.qml"
printf 'Temporary preferences: %s\nNetwork, device and application actions remain real.\n' "$preview"
"$QS" --path "$ROOT/quickshell/shell.qml" > >(tee "$preview/shell.log") 2>&1 &
child=$!
wait "$child"
