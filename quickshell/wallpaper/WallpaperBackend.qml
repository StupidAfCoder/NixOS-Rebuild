pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "../common"

Item {
    id: root
    property var wallpapers: []
    property bool applying: false
    readonly property bool syncingApps: appColors.running
    property string appSyncMessage: ""
    function syncLiveApps(path) {
        if (!path || syncingApps || applying || tryingColors) return;
        appSyncMessage = "";
        appColors.command = ["bash", Settings.repo + "scripts/sync-wallust.sh", path].concat(Settings.previewMode ? ["--live-from-preview"] : []);
        appColors.running = true;
    }
    Process {
        id: appColors
        stderr: StdioCollector { onStreamFinished: if (text.trim()) console.warn("[app colors]", text) }
        onExited: (code, status) => { root.appSyncMessage = code === 0 ? "Wallust written; Firefox refresh requested. Pywalfox must be enabled in Firefox." : "App colors could not be synchronized. Check the terminal log and Pywalfox connection."; }
    }
    property bool scanning: false
    readonly property bool tryingColors: previewApply.running || mascot.running
    property string lastError: ""
    property string previewPath: ""
    property string currentPath: ""
    property var previewColors: ({})
    property var pendingPreview: null
    property string previewResult: ""
    readonly property bool previewBusy: previewProc.running || pendingPreview !== null
    function refresh() { if (!scan.running) { scanning = true; scan.running = true; } }
    function argumentsFor(path, recipe, tone, saturation, source, contrast) {
        return ["python3", Settings.repo + "scripts/generate-theme.py", path, recipe === "paper" ? "light" : "dark", String(contrast), "--recipe", recipe, "--tone", String(tone), "--saturation", String(saturation), "--source", source];
    }
    function preview(path, recipe, tone, saturation, source, contrast) {
        pendingPreview = argumentsFor(path, recipe, tone, saturation, source, contrast).concat(["--preview"]);
        previewDelay.restart();
    }
    function runPreview() {
        if (previewProc.running || !pendingPreview) return;
        previewProc.command = pendingPreview;
        pendingPreview = null;
        previewResult = "";
        previewProc.running = true;
    }
    function tryColors(path, recipe, tone, saturation, source, contrast) {
        if (!Settings.previewMode || !path || tryingColors) return;
        previewApply.wallpaperPath = path;
        previewApply.settingsPatch = {recipe: recipe, tone: tone, saturation: saturation, source: source, contrast: contrast};
        previewApply.command = argumentsFor(path, recipe, tone, saturation, source, contrast).concat(["--output-dir", Settings.themeRoot]);
        previewApply.running = true;
    }
    Process {
        id: previewApply
        property string wallpaperPath: ""
        property var settingsPatch: ({})
        onExited: (code, status) => {
            if (code === 0) {
                root.lastError = "";
                Settings.patch(settingsPatch);
                root.previewPath = wallpaperPath;
                mascot.running = true;
            } else root.lastError = "Could not try this palette. No live wallpaper was changed.";
        }
    }
    Process { id: mascot; command: ["bash", Settings.repo + "quickshell/bar/scripts/generate-theme-assets.sh", Settings.themeFile] }
    function apply(path, recipe, tone, saturation, source, contrast) {
        if (Settings.previewMode) { lastError = "Native preview: wallpaper application is disabled; palette previews still work."; return; }
        if (applying || !path) return;
        lastError = "";
        applying = true;
        applyProc.command = ["bash", Settings.repo + "scripts/apply-wallpaper.sh", path, recipe, String(tone), String(saturation), source, String(contrast)];
        applyProc.running = true;
        Settings.patch({recipe: recipe, tone: tone, saturation: saturation, source: source, contrast: contrast});
    }
    function trash(path) {
        if (Settings.previewMode) { lastError = "Native preview: moving files to Trash is disabled."; return; }
        if (trashProc.running) return;
        trashProc.command = ["gio", "trash", "--", path];
        trashProc.running = true;
    }
    Component.onCompleted: refresh()
    Connections { target: Settings; function onWallpaperDirChanged() { root.refresh(); } }
    FileView {
        path: (Quickshell.env("XDG_STATE_HOME") || Settings.home + "/.local/state") + "/wallpaper/current"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.currentPath = text().trim()
    }
    Process {
        id: scan
        command: ["find", Settings.wallpaperDir, "-maxdepth", "1", "-type", "f", "(", "-iname", "*.png", "-o", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.webp", ")", "-print0"]
        stdout: StdioCollector {
            onStreamFinished: root.wallpapers = text.split("\u0000").filter(p => p.length > 0).map(p => ({name: p.substring(p.lastIndexOf("/") + 1), path: p})).sort((a,b) => a.name.localeCompare(b.name))
        }
        stderr: StdioCollector { onStreamFinished: { if (text.trim()) root.lastError = text.trim(); } }
        onExited: root.scanning = false
    }
    Process {
        id: applyProc
        stderr: StdioCollector { onStreamFinished: { if (text.trim()) console.warn("[wallpaper]", text); } }
        onExited: (code, status) => { root.applying = false; if (code !== 0) root.lastError = code === 2 ? "Wallpaper applied; app color sync failed. Check Wallust / Pywalfox in the shell log." : "Wallpaper could not be applied. Check the shell journal."; }
    }
    Timer { id: previewDelay; interval: 220; onTriggered: root.runPreview() }
    Process {
        id: previewProc
        stdout: StdioCollector { onStreamFinished: root.previewResult = text }
        onExited: (code, status) => {
            if (!root.pendingPreview && code === 0) {
                try { root.previewColors = JSON.parse(root.previewResult); root.lastError = ""; } catch(e) { root.lastError = "Preview was not valid"; }
            } else if (!root.pendingPreview && code !== 0) root.lastError = "No preview available for this image";
            root.runPreview();
        }
    }
    Process { id: trashProc; onExited: (code, status) => { if (code !== 0) root.lastError = "Could not move wallpaper to Trash"; root.refresh(); } }
}
