pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    property string homeDir: ""
    property string wallpaperDir: homeDir + "/Pictures/Wallpapers"
    property string applyScriptPath: homeDir + "/.nixos_dotfiles/scripts/apply-wallpaper.sh"
    property string failedLogPath: homeDir + "/.cache/wallust/failed_wallpapers.json"
    property var wallpapers: []
    property var failedPaths: []
    property bool applying: false
    property bool scanning: false

    function refresh() {
        scanning = true;
        if (root.homeDir === "")
            homeProc.running = true;
        else
            scanProc.running = true;
    }

    function apply(path) {
        root.applying = true;
        applyProc.command = ["bash", root.applyScriptPath, path];
        applyProc.running = true;
    }

    function isFailed(path) {
        return root.failedPaths.indexOf(path) !== -1;
    }

    function deleteWallpaper(path) {
        deleteProc.command = ["rm", "--", path];
        deleteProc.running = true;
    }

    Component.onCompleted: refresh()

    Process {
        id: homeProc
        command: ["sh", "-c", "printf %s \"$HOME\""]
        stdout: StdioCollector {
            onStreamFinished: {
                root.homeDir = this.text.trim();
                failedLogFile.reload();
                scanProc.running = true;
            }
        }
    }

    Process {
        id: scanProc
        command: ["find", root.wallpaperDir, "-maxdepth", "1", "-type", "f", "(", "-iname", "*.png", "-o", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.webp", ")", "-print0"]
        stdout: StdioCollector {
            onStreamFinished: {
                const found = [];
                for (const p of this.text.split("\u0000")) {
                    if (!p)
                        continue;
                    const name = p.substring(p.lastIndexOf("/") + 1).replace(/\.[^.]+$/, "");
                    found.push({
                        name: name,
                        path: p
                    });
                }
                found.sort((a, b) => a.name.localeCompare(b.name));
                root.wallpapers = found;
                root.scanning = false;
            }
        }
    }

    Process {
        id: applyProc
        stdout: StdioCollector {
            onStreamFinished: root.applying = false
        }
        stderr: StdioCollector {
            onStreamFinished: console.log("[wallpaper apply stderr]", this.text)
        }
    }

    Process {
        id: deleteProc
        stdout: StdioCollector {
            onStreamFinished: root.refresh()
        }
        stderr: StdioCollector {
            onStreamFinished: console.log("[wallpaper delete stderr]", this.text)
        }
    }

    // Written by prime-wallust-cache.sh; tells us which wallpapers have no palette.
    FileView {
        id: failedLogFile
        path: root.failedLogPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.failedPaths = JSON.parse(text());
            } catch (e) {
                root.failedPaths = [];
            }
        }
        onLoadFailed: root.failedPaths = []  // fine before the first run creates the file
    }
}
