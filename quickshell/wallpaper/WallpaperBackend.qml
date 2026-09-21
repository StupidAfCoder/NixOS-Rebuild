pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "../common"

Item {
    id: root
    property var wallpapers: []
    property bool applying: false
    readonly property bool trashing: trashProc.running
    signal wallpaperTrashed(string path)
    readonly property bool syncingApps: appColors.running
    property string appSyncMessage: ""
    function syncLiveApps(path) {
        if (!path || syncingApps || applying || tryingColors || trashing) return;
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
    property string actionError: ""
    property string scanError: ""
    property string previewError: ""
    readonly property string lastError: actionError || scanError || previewError
    property bool rescanRequested: false
    property string previewPath: ""
    property string currentPath: ""
    property var previewColors: ({})
    property var pendingPreview: null
    property int previewRevision: 0
    property string previewResult: ""
    readonly property bool previewBusy: (previewProc.running && previewProc.revision === previewRevision) || pendingPreview !== null
    function refresh() { rescanRequested = true; runScan(); }
    function runScan() {
        if (scan.running || !rescanRequested) return;
        rescanRequested = false;
        scan.directory = Settings.wallpaperDir;
        scan.output = ""; scan.errorOutput = "";
        scanError = ""; scanning = true; scan.running = true;
    }
    function argumentsFor(path, recipe, tone, saturation, source, contrast) {
        return ["python3", Settings.repo + "scripts/generate-theme.py", path, recipe === "paper" ? "light" : "dark", String(contrast), "--recipe", recipe, "--tone", String(tone), "--saturation", String(saturation), "--source", source];
    }
    function preview(path, recipe, tone, saturation, source, contrast) {
        if (!path) { cancelPreview(); return; }
        previewRevision += 1;
        previewColors = ({}); previewError = "";
        pendingPreview = argumentsFor(path, recipe, tone, saturation, source, contrast).concat(["--preview"]);
        previewDelay.restart();
    }
    function runPreview() {
        if (previewProc.running || !pendingPreview) return;
        previewProc.command = pendingPreview;
        previewProc.revision = previewRevision;
        pendingPreview = null;
        previewResult = "";
        previewProc.running = true;
    }
    function cancelPreview() {
        // The running read-only process may finish, but cannot publish after
        // the editor closes or its selection is cleared. Do not kill an apply.
        previewRevision += 1;
        pendingPreview = null;
        previewDelay.stop();
        previewColors = ({}); previewError = "";
    }
    function finishPreview(code, revision, output) {
        if (revision !== previewRevision || pendingPreview) return;
        if (code !== 0) { previewError = "No preview available for this image"; return; }
        try {
            const colors = JSON.parse(output);
            const roles = ["background", "surface_container", "outline", "accent", "on_surface"];
            if (!colors || typeof colors !== "object" || Array.isArray(colors)
                || !roles.every(role => typeof colors[role] === "string" && /^#[0-9a-f]{6}$/i.test(colors[role])))
                throw new Error("Incomplete palette");
            previewColors = colors; previewError = "";
        } catch(e) { previewColors = ({}); previewError = "Preview was not valid"; }
    }
    function tryColors(path, recipe, tone, saturation, source, contrast) {
        if (!Settings.previewMode || !path || tryingColors || applying || syncingApps || trashing) return;
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
                root.actionError = "";
                Settings.patch(settingsPatch);
                root.previewPath = wallpaperPath;
                mascot.running = true;
            } else root.actionError = "Could not try this palette. No live wallpaper was changed.";
        }
    }
    Process { id: mascot; command: ["bash", Settings.repo + "quickshell/bar/scripts/generate-theme-assets.sh", Settings.themeFile] }
    function apply(path, recipe, tone, saturation, source, contrast) {
        if (Settings.previewMode) { actionError = "Native preview: wallpaper application is disabled; palette previews still work."; return; }
        if (applying || tryingColors || syncingApps || trashing || !path) return;
        actionError = "";
        applying = true;
        applyProc.command = ["bash", Settings.repo + "scripts/apply-wallpaper.sh", path, recipe, String(tone), String(saturation), source, String(contrast)];
        applyProc.settingsPatch = {recipe: recipe, tone: tone, saturation: saturation, source: source, contrast: contrast};
        applyProc.running = true;
    }
    function trash(path) {
        if (Settings.previewMode) { actionError = "Native preview: moving files to Trash is disabled."; return; }
        if (!path || trashing || applying || tryingColors || syncingApps) return;
        actionError = "";
        trashProc.wallpaperPath = path;
        trashProc.command = ["gio", "trash", "--", path];
        trashProc.running = true;
    }
    function finishTrash(code, path) {
        if (code === 0) {
            actionError = "";
            wallpaperTrashed(path);
        } else actionError = "Could not move wallpaper to Trash";
        refresh();
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
        property string directory: ""
        property string output: ""
        property string errorOutput: ""
        command: ["find", directory, "-maxdepth", "1", "-type", "f", "(", "-iname", "*.png", "-o", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.webp", ")", "-print0"]
        stdout: StdioCollector { onStreamFinished: scan.output = text }
        stderr: StdioCollector { onStreamFinished: scan.errorOutput = text.trim() }
        onExited: (code, status) => {
            // A newer folder request wins; do not flash the old folder's results.
            if (directory === Settings.wallpaperDir && !root.rescanRequested) {
                root.wallpapers = code === 0 ? output.split("\u0000").filter(p => p.length > 0).map(p => ({name: p.substring(p.lastIndexOf("/") + 1), path: p})).sort((a,b) => a.name.localeCompare(b.name)) : [];
                root.scanError = code === 0 ? "" : errorOutput || "Could not read the wallpaper folder.";
            }
            root.scanning = root.rescanRequested;
            Qt.callLater(function() { root.runScan(); });
        }
    }
    Process {
        id: applyProc
        property var settingsPatch: ({})
        stderr: StdioCollector { onStreamFinished: { if (text.trim()) console.warn("[wallpaper]", text); } }
        onExited: (code, status) => {
            root.applying = false;
            // Exit 2 means the wallpaper changed, but a follow-up theme step failed.
            if (code === 0 || code === 2) Settings.patch(settingsPatch);
            if (code !== 0) root.actionError = code === 2 ? "Wallpaper changed; some theme updates failed. Check the shell log." : "Wallpaper could not be applied. Check the shell log.";
        }
    }
    Timer { id: previewDelay; interval: 220; onTriggered: root.runPreview() }
    Process {
        id: previewProc
        property int revision: -1
        stdout: StdioCollector { onStreamFinished: root.previewResult = text }
        onExited: (code, status) => {
            root.finishPreview(code, revision, root.previewResult);
            Qt.callLater(function() { root.runPreview(); });
        }
    }
    Process {
        id: trashProc
        property string wallpaperPath: ""
        onExited: (code, status) => root.finishTrash(code, wallpaperPath)
    }
}
