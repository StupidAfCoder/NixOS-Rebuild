#!/usr/bin/env python3
"""Launch the real NM editor with observable availability/start/exit reporting."""
import os
import shutil
import subprocess
import sys


def main():
    executable = shutil.which("nm-connection-editor")
    if not executable:
        print("nm-connection-editor is not installed. Install networkmanagerapplet in your live environment; the preview does not install packages. This editor supports both Ethernet and Wi-Fi.", file=sys.stderr)
        return 127
    env = os.environ.copy()
    if env.get("PIXEL_SHELL_PREVIEW") == "1":
        for kind in ("CONFIG", "CACHE", "STATE"):
            if env.get("PIXEL_SHELL_LIVE_" + kind):
                env["XDG_" + kind + "_HOME"] = env["PIXEL_SHELL_LIVE_" + kind]
    try:
        child = subprocess.Popen([executable], env=env, stdout=subprocess.DEVNULL)
    except OSError as error:
        print(f"Could not start the connection editor: {error}", file=sys.stderr)
        return 1
    # Sent only once exec succeeded. The shell can now release its input layer.
    print("started", flush=True)
    return child.wait()


if __name__ == "__main__":
    sys.exit(main())
