pragma Singleton
import QtQuick
import Quickshell
QtObject {
    function entry(app) {
        if (!app) return null;
        const key = String(app).toLowerCase();
        return DesktopEntries.byId(app) || DesktopEntries.applications.values.find(e => (e.startupClass || "").toLowerCase() === key || e.name.toLowerCase() === key) || null;
    }
    function name(app) { const found = entry(app); return found ? found.name : app; }
    function icon(app) { const found = entry(app); return Quickshell.iconPath(found?.icon || app, true); }
    function fallback(app) {
        if (!app) return null;
        const key = app.toLowerCase();
        if (/firefox|chrom|browser/.test(key)) return "globe.svg";
        if (/emacs|code|vim/.test(key)) return "braces.svg";
        if (/foot|kitty|terminal|alacritty/.test(key)) return "terminal.svg";
        return "app-windows.svg";
    }
}
