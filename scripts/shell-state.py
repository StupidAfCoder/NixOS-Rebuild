#!/usr/bin/env python3
"""Local shell preferences, opt-in focused-app history and conservative workspace audio.
No window titles, URLs, keystrokes or screenshots are collected. No network requests.
"""
import argparse
import copy
import fcntl
import json
import math
import os
import signal
import subprocess
import tempfile
import time
from datetime import datetime
from pathlib import Path

HOME = Path.home()
CONFIG = Path(os.environ.get("XDG_CONFIG_HOME", HOME / ".config")) / "pixel-shell/settings.json"
STATE = Path(os.environ.get("XDG_STATE_HOME", HOME / ".local/state")) / "pixel-shell"
BAR_MODULES = ("launcher", "workspaces", "clock", "wizard", "media", "audio", "system", "battery", "network", "bluetooth", "tray", "settings", "power")
DEFAULTS = dict(displayName=os.environ.get("USER", "User"), avatarPath="", bio="A little magic, every day.",
                videoPath=str(HOME / "Videos/pixel-traffic.mp4"), wallpaperDir=str(HOME / "Pictures/Wallpapers"),
                frameWidth=6, barWidth=44, motionMs=180, reducedMotion=False, bodySize=13,
                recipe="balanced", tone=0, saturation=1., source="representative", contrast=0.,
                trackingEnabled=False, retentionDays=30, workspaceAudioEnabled=False,
                mutedWorkspaces=[], dailyGoalMinutes=240,
                barLayout={"top": ["launcher", "workspaces"], "middle": ["wizard", "media", "clock"],
                           "bottom": ["audio", "system", "battery", "network", "bluetooth", "tray", "settings", "power"]},
                clockShowDate=False, barModules={key: key not in ("system", "settings") for key in BAR_MODULES}, workspaceCount=5, launcherEdge="top", quickWallpaperEdgeEnabled=True)


def load(path, fallback):
    try:
        return json.loads(Path(path).read_text())
    except (OSError, ValueError):
        return fallback


def save(path, data):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as f:
        name = f.name
        json.dump(data, f, indent=2)
        f.write("\n")
        f.flush()
        os.fsync(f.fileno())
    try:
        os.replace(name, path)
    finally:
        if os.path.exists(name):
            os.unlink(name)


def validate(values):
    result = copy.deepcopy(DEFAULTS)
    if not isinstance(values, dict):
        raise ValueError("Settings must be an object")
    enums = {"recipe": ("balanced", "wallpaper", "black", "neutral", "tonal", "expressive", "paper", "mono"),
             "source": ("representative", "dominant", "colorful"),
             "launcherEdge": ("top", "bottom", "center")}
    limits = {"frameWidth": (4, 10), "barWidth": (36, 64), "motionMs": (80, 350), "bodySize": (12, 18),
              "tone": (-15, 15), "saturation": (0, 1.6), "contrast": (0, 1),
              "retentionDays": (1, 90), "dailyGoalMinutes": (15, 1440), "workspaceCount": (1, 10)}
    for key, value in values.items():
        if key not in DEFAULTS:
            continue
        if key == "barModules":
            if not isinstance(value, dict) or any(k not in BAR_MODULES or type(v) is not bool for k, v in value.items()):
                raise ValueError("barModules expects known module names and boolean values")
            value = {**DEFAULTS["barModules"], **value}
        elif key == "barLayout":
            if not isinstance(value, dict) or set(value) != {"top", "middle", "bottom"} or any(not isinstance(v, list) for v in value.values()):
                raise ValueError("barLayout expects top, middle and bottom lists")
            ordered = [v for zone in ("top", "middle", "bottom") for v in value[zone]]
            if any(not isinstance(v, str) for v in ordered) or len(ordered) != len(BAR_MODULES) or set(ordered) != set(BAR_MODULES):
                raise ValueError("barLayout must contain every module exactly once")
            value = copy.deepcopy(value)
        elif key in enums:
            if value not in enums[key]:
                raise ValueError(f"Invalid {key}")
        elif key in limits:
            lo, hi = limits[key]
            if isinstance(value, bool) or not isinstance(value, (int, float)) or not lo <= value <= hi:
                raise ValueError(f"{key} must be between {lo} and {hi}")
            if key not in ("tone", "saturation", "contrast"):
                value = int(value)
        elif key == "mutedWorkspaces":
            if not isinstance(value, list) or len(value) > 100 or not all(type(v) is int and v > 0 for v in value):
                raise ValueError("Invalid workspace list")
            value = sorted(set(value))
        elif isinstance(DEFAULTS[key], bool):
            if type(value) is not bool:
                raise ValueError(f"{key} must be boolean")
        elif not isinstance(value, str) or len(value) > 4096:
            raise ValueError(f"Invalid {key}")
        result[key] = value
    return result


def settings():
    try:
        return validate(load(CONFIG, {}))
    except ValueError:
        return copy.deepcopy(DEFAULTS)


def command(args, json_output=False):
    try:
        p = subprocess.run(args, capture_output=True, text=True, timeout=3, check=True)
        return json.loads(p.stdout) if json_output else p.stdout.strip()
    except (OSError, subprocess.SubprocessError, ValueError):
        return None


def stream_workspace(pid, clients, parent_lookup=None):
    """Resolve exact process or ancestor. Ambiguous shared-process apps are never muted."""
    def parent_of(p):
        try:
            # comm can contain spaces/parentheses; fields after the final ')' are stable.
            return int(Path(f"/proc/{p}/stat").read_text().rsplit(")", 1)[1].split()[1])
        except (OSError, ValueError, IndexError):
            return 0
    parent_lookup = parent_lookup or parent_of
    for _ in range(20):
        if pid <= 1:
            break
        matches = {c.get("workspace", {}).get("id") for c in clients if c.get("pid") == pid}
        matches.discard(None)
        if matches:
            return next(iter(matches)) if len(matches) == 1 else None
        pid = parent_lookup(pid)
    return None


def stream_key(stream):
    props = stream.get("properties", {})
    serial = props.get("object.serial")
    pid = props.get("application.process.id")
    # Index alone can be recycled; never restore somebody else's stream.
    return f"{stream.get('index')}:{serial}:{pid}" if serial and pid else None


def audio_tick(config, owned):
    streams = command(["pactl", "-f", "json", "list", "sink-inputs"], True)
    clients = command(["hyprctl", "-j", "clients"], True)
    if streams is None or clients is None:
        return owned, "Audio mapping unavailable (requires PipeWire-Pulse and Hyprland)."
    selected = set(config["mutedWorkspaces"]) if config["workspaceAudioEnabled"] else set()
    live = {}
    skipped = 0
    for stream in streams:
        key = stream_key(stream)
        try:
            pid = int(stream.get("properties", {}).get("application.process.id", 0))
        except (TypeError, ValueError):
            pid = 0
        ws = stream_workspace(pid, clients)
        if ws is None or key is None:
            skipped += 1
        should_mute = key is not None and ws in selected
        if should_mute:
            if key in owned:
                live[key] = owned[key]
                if not stream.get("mute", False):
                    command(["pactl", "set-sink-input-mute", str(stream["index"]), "1"])
            elif not stream.get("mute", False):
                if command(["pactl", "set-sink-input-mute", str(stream["index"]), "1"]) is not None:
                    live[key] = {"index": stream["index"]}
        elif key in owned:
            if command(["pactl", "set-sink-input-mute", str(stream["index"]), "0"]) is None:
                live[key] = owned[key]  # retry restoration next tick
    return live, f"{len(live)} stream(s) muted; {skipped} unmapped/shared stream(s) untouched."


def add_usage(days, day, app, seconds):
    if seconds <= 0 or not app:
        return
    entry = days.setdefault(day, {})
    app = app[:160]
    entry[app] = round(entry.get(app, 0) + min(seconds, 5), 2)


def prune(days, retention, today=None):
    today = today or datetime.now().date()
    result = {}
    if not isinstance(days, dict):
        return result
    for day, values in days.items():
        try:
            parsed = datetime.strptime(day, "%Y-%m-%d").date()
            if parsed.isoformat() != day:
                continue
            age = (today - parsed).days
        except (ValueError, TypeError):
            continue
        if not 0 <= age < retention or not isinstance(values, dict):
            continue
        result[day] = {app: value for app, value in values.items()
                       if isinstance(app, str) and app not in ("__proto__", "constructor", "prototype")
                       and type(value) in (int, float) and math.isfinite(value) and 0 <= value <= 86400}
    return result


def daemon():
    STATE.mkdir(parents=True, exist_ok=True, mode=0o700)
    # One collector, even if launched manually alongside systemd.
    lock = (STATE / "daemon.lock").open("w")
    fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    running = True

    def stop(*_):
        nonlocal running
        running = False
    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
    owned = load(STATE / "audio-owned.json", {})
    save(STATE / "idle.json", False)
    last = time.monotonic()
    previous = None
    last_flush = 0
    history = load(STATE / "usage.json", {})
    days = prune(history.get("days", {}) if isinstance(history, dict) else {}, settings()["retentionDays"])
    generation = load(STATE / "usage-reset.json", 0)
    while running:
        cfg = settings()
        reset = load(STATE / "usage-reset.json", 0)
        if generation != reset:
            days, generation = {}, reset
            last_flush = 0
        now = time.monotonic()
        elapsed = now - last
        last = now
        today = datetime.now().strftime("%Y-%m-%d")
        current = None
        idle = load(STATE / "idle.json", False)
        session = os.environ.get("XDG_SESSION_ID")
        locked = session and command(["loginctl", "show-session", session, "-p", "LockedHint", "--value"]) == "yes"
        if cfg["trackingEnabled"]:
            days.setdefault(today, {})  # known zero differs from never observed
        if cfg["trackingEnabled"] and not idle and not locked:
            monitors = command(["hyprctl", "-j", "monitors"], True)
            win = command(["hyprctl", "-j", "activewindow"], True)
            if monitors and any(m.get("dpmsStatus", True) for m in monitors) and win:
                current = (today, win.get("class", ""))
        # Count only intervals with the same focused app, never suspend gaps or disabled time.
        if current and current == previous and elapsed <= 5:
            add_usage(days, *current, elapsed)
        previous = current
        status = "Workspace audio is disabled."
        if cfg["workspaceAudioEnabled"] or owned:
            owned, status = audio_tick(cfg, owned)
            save(STATE / "audio-owned.json", owned)
        if now - last_flush >= 15:
            days = prune(days, cfg["retentionDays"])
            save(STATE / "usage.json", {"days": days, "updated": datetime.now().isoformat(),
                                       "tracking": cfg["trackingEnabled"], "idle": idle})
            save(STATE / "status.json", {"audio": status, "updated": datetime.now().isoformat()})
            last_flush = now
        time.sleep(2)
    # Restore only streams this collector actually muted, preserving pre-existing mutes.
    owned, _ = audio_tick({**settings(), "workspaceAudioEnabled": False}, owned)
    save(STATE / "audio-owned.json", owned)
    save(STATE / "usage.json", {"days": days, "updated": datetime.now().isoformat(), "tracking": False})


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("action", choices=("init", "patch", "daemon", "idle", "clear-history", "toggle-workspace", "theme-args"))
    p.add_argument("value", nargs="?")
    a = p.parse_args()
    try:
        if a.action == "theme-args":
            cfg = settings()
            print("\n".join(str(cfg[k]) for k in ("recipe", "tone", "saturation", "source", "contrast")))
        elif a.action == "init" and CONFIG.exists():
            return
        elif a.action == "daemon":
            daemon()
        elif a.action == "idle":
            if a.value not in ("true", "false"):
                raise ValueError("idle expects true or false")
            save(STATE / "idle.json", a.value == "true")
        elif a.action == "clear-history":
            save(STATE / "usage-reset.json", time.time_ns())
            save(STATE / "usage.json", {"days": {}})
        else:
            CONFIG.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
            with (CONFIG.parent / ".settings.lock").open("w") as lock:
                fcntl.flock(lock, fcntl.LOCK_EX)
                cfg = settings()
                if a.action == "patch":
                    patch = json.loads(a.value)
                    if not isinstance(patch, dict):
                        raise ValueError("Patch must be an object")
                    if "barModules" in patch and isinstance(patch["barModules"], dict):
                        patch["barModules"] = {**cfg["barModules"], **patch["barModules"]}
                    cfg = validate({**cfg, **patch})
                elif a.action == "toggle-workspace":
                    workspace = int(a.value)
                    values = set(cfg["mutedWorkspaces"])
                    values.symmetric_difference_update({workspace})
                    cfg = validate({**cfg, "mutedWorkspaces": list(values)})
                save(CONFIG, cfg)
    except (ValueError, OSError) as exc:
        p.exit(1, f"pixel-shell: {exc}\n")


if __name__ == "__main__":
    main()
