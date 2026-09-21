#!/usr/bin/env python3
"""Explicit, session-only Hyprland rule for a uniquely named preview layer.

Never edits config files or enables global blur. Cleanup disables only our rule;
Hyprland discards the disabled rule on its next configuration reload.
"""
import argparse
import json
import re
import subprocess
import sys


def run(args):
    result = subprocess.run(["hyprctl", *args], capture_output=True, text=True, timeout=5)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip() or "hyprctl failed")
    return result.stdout.strip()


def set_rule(token, enabled):
    if not re.fullmatch(r"[0-9a-f]{24}", token):
        raise ValueError("Invalid preview rule token")
    key = "pixel_shell_preview_blur_" + token
    if enabled:
        option = json.loads(run(["-j", "getoption", "decoration:blur:enabled"]))
        if not isinstance(option, dict):
            raise RuntimeError("Could not read the compositor blur option")
        # Lua-era Hyprland returns a JSON bool; older builds used int 0/1.
        value = option.get("bool", option.get("int"))
        if not (value is True or (type(value) is int and value == 1)):
            raise RuntimeError("Compositor blur is disabled. Enable it in your own Hyprland settings first; preview will not change that global option.")
        code = f'''if _G.{key} then _G.{key}:set_enabled(false) end
_G.{key} = hl.layer_rule({{ name = "pixel-preview-blur-{token}", match = {{ namespace = "^quickshell:preview-blur-{token}$" }}, blur = true, ignore_alpha = 0.2, no_anim = true }})'''
    else:
        code = f'if _G.{key} then _G.{key}:set_enabled(false); _G.{key} = nil end'
    output = run(["eval", code])
    if output.lower() != "ok":
        raise RuntimeError(output or "Hyprland did not acknowledge the preview rule")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["enable", "disable"])
    parser.add_argument("token")
    args = parser.parse_args()
    try:
        set_rule(args.token, args.action == "enable")
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
        print(f"Preview blur: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
