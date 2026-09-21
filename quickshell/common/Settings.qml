pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "ModuleCatalog.js" as Modules
import "PopupGeometry.js" as Geometry

Item {
    id: root
    readonly property bool previewMode: Quickshell.env("PIXEL_SHELL_PREVIEW") === "1"
    readonly property string home: Quickshell.env("HOME")
    readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || home + "/.config") + "/pixel-shell"
    readonly property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || home + "/.cache") + "/quickshell"
    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || home + "/.local/state") + "/pixel-shell"
    readonly property string repo: (Quickshell.env("PIXEL_SHELL_ROOT") || Quickshell.shellPath("..")).replace(/\/+$/, "") + "/"
    readonly property string themeRoot: previewMode ? cacheDir + "/preview-theme/" : repo
    readonly property string themeFile: themeRoot + "quickshell/bar/theme/colors.json"
    property var persisted: ({})
    readonly property var values: merge(merge(persisted, inFlight), pending)
    property string error: ""
    property var pending: ({})
    property var inFlight: ({})
    readonly property bool saving: writer.running || Object.keys(pending).length > 0
    readonly property var moduleCatalog: Modules.entries()
    readonly property var barModules: Object.assign({}, Modules.defaults(), values.barModules || {})
    readonly property var barLayout: Modules.layout(values.barLayout)
    readonly property bool clockShowDate: values.clockShowDate === true
    function relocateModule(key, zone, offset) { patch({barLayout: Modules.relocate(barLayout, key, zone, offset)}); }
    function resetLayout() { patch({barLayout: Modules.layoutDefaults()}); }
    readonly property int workspaceCount: bounded("workspaceCount", 5, 1, 10)
    function moduleEnabled(key) { return barModules[key] !== false; }
    function setModule(key, enabled) {
        const changes = {};
        changes[key] = enabled;
        patch({barModules: changes});
    }
    readonly property string displayName: values.displayName || Quickshell.env("USER") || "User"
    readonly property string avatarPath: values.avatarPath || ""
    readonly property string bio: values.bio || "A little magic, every day."
    readonly property string videoPath: values.videoPath || home + "/Videos/pixel-traffic.mp4"
    readonly property string wallpaperDir: values.wallpaperDir || home + "/Pictures/Wallpapers"
    readonly property int frameWidth: bounded("frameWidth", 6, 4, 10)
    readonly property int barWidth: bounded("barWidth", 44, 36, 64)
    readonly property string barEdge: ["left", "right", "top", "bottom"].indexOf(values.barEdge) >= 0 ? values.barEdge : "left"
    readonly property bool horizontalBar: barEdge === "top" || barEdge === "bottom"
    readonly property real barOpacity: bounded("barOpacity", 1, .35, 1)
    readonly property bool barBlur: values.barBlur === true
    readonly property var desktopInsets: Geometry.insets(barEdge, barWidth, frameWidth)
    readonly property int bodySize: bounded("bodySize", 13, 12, 18)
    readonly property bool reducedMotion: values.reducedMotion === true
    readonly property int motionMs: reducedMotion ? 0 : bounded("motionMs", 180, 80, 350)
    readonly property bool quickWallpaperEdgeEnabled: values.quickWallpaperEdgeEnabled !== false
    readonly property string launcherEdge: ["top", "bottom", "center"].indexOf(values.launcherEdge) >= 0 ? values.launcherEdge : "top"
    readonly property string recipe: ["balanced", "wallpaper", "black", "neutral", "tonal", "expressive", "paper", "mono"].indexOf(values.recipe) >= 0 ? values.recipe : "balanced"
    readonly property real tone: bounded("tone", 0, -15, 15)
    readonly property real saturation: bounded("saturation", 1, 0, 1.6)
    readonly property string sourcePreference: ["representative", "dominant", "colorful"].indexOf(values.source) >= 0 ? values.source : "representative"
    readonly property real contrast: bounded("contrast", 0, 0, 1)
    readonly property bool trackingEnabled: values.trackingEnabled === true
    readonly property bool workspaceAudioEnabled: values.workspaceAudioEnabled === true
    readonly property var mutedWorkspaces: Array.isArray(values.mutedWorkspaces) ? values.mutedWorkspaces : []
    readonly property int dailyGoalMinutes: bounded("dailyGoalMinutes", 240, 15, 1440)
    function bounded(key, fallback, lo, hi) {
        const v = values[key];
        return typeof v === "number" && isFinite(v) ? Math.max(lo, Math.min(hi, v)) : fallback;
    }
    function fileUrl(path) { return path ? "file://" + path.split("/").map(encodeURIComponent).join("/") : ""; }
    function merge(base, changes) {
        const result = Object.assign({}, base, changes);
        if (base.barModules || changes.barModules)
            result.barModules = Object.assign({}, base.barModules || {}, changes.barModules || {});
        return result;
    }
    function patch(changes) {
        pending = merge(pending, changes);
        flush.restart();
    }
    Timer { id: flush; interval: 180; onTriggered: root.savePending() }
    function savePending() {
        if (writer.running || Object.keys(pending).length === 0) return;
        const changes = pending;
        inFlight = changes;
        pending = ({});
        writer.command = ["python3", repo + "scripts/shell-state.py", "patch", JSON.stringify(changes)];
        writer.running = true;
    }
    FileView {
        id: file
        path: root.configDir + "/settings.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const data = JSON.parse(text());
                if (!data || typeof data !== "object" || Array.isArray(data)) throw new Error("Expected a JSON object");
                if (!writer.running) root.persisted = data;
                if (root.error.indexOf("Settings not loaded:") === 0) root.error = "";
            } catch (e) { root.error = "Settings not loaded: " + e; }
        }
    }
    Process {
        id: writer
        property string failure: ""
        onStarted: failure = ""
        stderr: StdioCollector { onStreamFinished: writer.failure = text.trim() }
        onExited: (code, status) => {
            if (code === 0) {
                root.persisted = root.merge(root.persisted, root.inFlight);
                root.error = "";
            } else root.error = failure || "Settings could not be saved";
            root.inFlight = ({});
            if (code === 0) file.reload();
            root.savePending();
        }
    }
    Process { command: ["python3", root.repo + "scripts/shell-state.py", "init"]; running: true; onExited: file.reload() }
}
