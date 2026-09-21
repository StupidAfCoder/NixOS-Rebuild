#!/usr/bin/env bash
# Run this checkout without replacing ~/.config/quickshell or applying a Nix generation.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ "${1:-}" == --help ]]; then
    echo 'usage: preview-shell.sh [--sample-history] [--software-video] [--preview-blur]'
    echo 'Temporarily stops the quickshell user service; restores it when preview exits.'
    echo 'Uses private temporary settings/history/cache. Power, wallpaper apply and Trash are disabled.'
    echo 'App launches, network, Bluetooth and audio controls still use the real session.'
    echo '--preview-blur explicitly adds a uniquely scoped temporary compositor rule, disabled on exit.'
    echo 'Sync live app colors requires separate confirmation and writes real Wallust templates.'
    exit 0
fi
sample=0
software_video=0
preview_blur=0
blur_token=""
unset PIXEL_SHELL_PREVIEW_BLUR PIXEL_SHELL_BLUR_NAMESPACE
for option in "$@"; do
    case "$option" in
        --sample-history) sample=1 ;;
        --software-video) software_video=1 ;;
        --preview-blur) preview_blur=1 ;;
        *) echo 'Unknown option; use --help' >&2; exit 2 ;;
    esac
done
[[ -n "${WAYLAND_DISPLAY:-}" ]] || { echo 'Run this from a terminal in your Wayland desktop.' >&2; exit 1; }
QS="$(command -v quickshell || command -v qs || true)"
[[ -n "$QS" ]] || { echo 'Quickshell must already be installed.' >&2; exit 1; }
command -v python3 >/dev/null
python3 -c 'from PIL import Image; from materialyoucolor.hct import Hct' || {
    echo 'Use your configured Python with Pillow and materialyoucolor.' >&2; exit 1;
}
preview="$(mktemp -d "${XDG_RUNTIME_DIR:-/tmp}/pixel-shell-preview.XXXXXX")"
# Preserve your avatar/video/path preferences, but never record or control workspace streams here.
original_state="${XDG_STATE_HOME:-$HOME/.local/state}"
original_config="${XDG_CONFIG_HOME:-$HOME/.config}/pixel-shell/settings.json"
mkdir -p "$preview/config/pixel-shell" "$preview/state/pixel-shell" "$preview/cache"
[[ ! -f "$original_config" ]] || cp -- "$original_config" "$preview/config/pixel-shell/settings.json"
[[ ! -f "${original_config%/*}/keybindings.lua" ]] || cp -- "${original_config%/*}/keybindings.lua" "$preview/config/pixel-shell/keybindings.lua"
export PIXEL_SHELL_LIVE_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
export PIXEL_SHELL_LIVE_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}"
export PIXEL_SHELL_LIVE_STATE="$original_state"
export XDG_CONFIG_HOME="$preview/config" XDG_STATE_HOME="$preview/state" XDG_CACHE_HOME="$preview/cache"
export PIXEL_SHELL_PREVIEW=1 PIXEL_SHELL_ROOT="$ROOT"
if [[ "$software_video" == 1 ]]; then
    export QT_FFMPEG_DECODING_HW_DEVICE_TYPES=,
    export QT_DISABLE_HW_TEXTURES_CONVERSION=1
fi
mkdir -p "$preview/state/wallpaper" "$preview/cache/quickshell/preview-theme/quickshell/bar/theme"
if [[ -f "$original_state/wallpaper/current" ]]; then
    cp -- "$original_state/wallpaper/current" "$preview/state/wallpaper/current"
else
    : > "$preview/state/wallpaper/current"
fi
printf '%s\n' '{"audio":"Workspace audio is not running in this preview."}' > "$preview/state/pixel-shell/status.json"
printf '%s\n' '{"days":{}}' > "$preview/state/pixel-shell/usage.json"
cp -- "$ROOT/quickshell/bar/theme/colors.json" "$preview/cache/quickshell/preview-theme/quickshell/bar/theme/colors.json"
bash "$ROOT/quickshell/bar/scripts/generate-theme-assets.sh" "$preview/cache/quickshell/preview-theme/quickshell/bar/theme/colors.json"
python3 "$ROOT/scripts/shell-state.py" patch '{"trackingEnabled":false,"workspaceAudioEnabled":false}'
if [[ "$sample" == 1 ]]; then
    rm -- "$preview/state/pixel-shell/usage.json"
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
    if [[ -n "$blur_token" ]]; then
        python3 "$ROOT/scripts/preview-blur.py" disable "$blur_token" || echo 'Could not disable the scoped preview blur rule; a compositor config reload clears it.' >&2
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
if [[ "$preview_blur" == 1 ]]; then
    blur_token="$(python3 -c 'import secrets; print(secrets.token_hex(12))')"
    if python3 "$ROOT/scripts/preview-blur.py" enable "$blur_token"; then
        export PIXEL_SHELL_PREVIEW_BLUR=1 PIXEL_SHELL_BLUR_NAMESPACE="quickshell:preview-blur-$blur_token"
        python3 "$ROOT/scripts/shell-state.py" patch '{"barBlur":true,"barOpacity":0.8}'
        echo 'Blur preview: temporary scoped rule enabled; private rail opacity is 80%. Live preferences unchanged.'
    else
        echo 'Continuing without the temporary blur rule. See the error above.' >&2
    fi
fi
printf 'Native preview: %s\nCtrl+C here to exit and restore your original service.\n' "$ROOT"
printf 'Open from another terminal: qs ipc --path %q call settings toggle\n' "$ROOT/quickshell/shell.qml"
printf 'Temporary preferences: %s\nNetwork, device and application actions remain real.\n' "$preview"
"$QS" --path "$ROOT/quickshell/shell.qml" > >(tee "$preview/shell.log") 2>&1 &
child=$!
wait "$child"
