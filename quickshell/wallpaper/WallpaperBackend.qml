pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    property string homeDir: ""
    property string wallpaperDir: homeDir + "/Pictures/Wallpapers"
    property string applyScriptPath: homeDir + "/.nixos_dotfiles/scripts/apply-wallpaper.sh"

    property var wallpapers: []
    property bool applying: false
    property bool scanning: false

    function refresh() {
        scanning = true
        if (root.homeDir === "") homeProc.running = true
        else scanProc.running = true
    }

    function apply(path) {
        root.applying = true
        applyProc.command = ["bash", root.applyScriptPath, path]
        applyProc.running = true
    }

    Component.onCompleted: {
        refresh()
    }

    // Resolve $HOME once via the shell, since it's the one thing we
    // genuinely can't hardcode -- this replaces the earlier
    // Quickshell.env() guess, which wasn't resolving correctly.
    Process {
        id: homeProc
        command: ["sh", "-c", "printf %s \"$HOME\""]
        stdout: StdioCollector {
            onStreamFinished: {
                root.homeDir = this.text.trim()
                scanProc.running = true
            }
        }
    }

    Process {
        id: scanProc
        command: ["find", root.wallpaperDir, "-maxdepth", "1", "-type", "f",
            "(", "-iname", "*.png", "-o", "-iname", "*.jpg",
            "-o", "-iname", "*.jpeg", "-o", "-iname", "*.webp", ")",
            "-print0"]
        stdout: StdioCollector {
            onStreamFinished: {
                const found = []
                for (const p of this.text.split("\u0000")) {
                    if (!p) continue
                    const name = p.substring(p.lastIndexOf("/") + 1).replace(/\.[^.]+$/, "")
                    found.push({ name: name, path: p })
                }
                found.sort((a, b) => a.name.localeCompare(b.name))
                root.wallpapers = found
                root.scanning = false
            }
        }
    }

    Process {
        id: applyProc
        stdout: StdioCollector { onStreamFinished: root.applying = false }
        stderr: StdioCollector { onStreamFinished: console.log("[wallpaper apply stderr]", this.text) }
    }
}