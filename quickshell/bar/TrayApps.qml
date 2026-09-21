pragma Singleton
import QtQuick
import Quickshell.Services.SystemTray as TrayService

QtObject {
    property bool shown: false
    readonly property var items: TrayService.SystemTray.items.values
    function toggle() { shown = !shown; }
    function hide() { shown = false; }
    function iconFor(item) {
        // Use bundled symbols rather than rendering a theme provider's missing-texture image.
        // This is identity-based fallback, not unreliable screenshot/color detection.
        const name = ((item.id || "") + " " + (item.title || "")).toLowerCase();
        if (/udisk|removable|mount/.test(name)) return "database.svg";
        if (/cloudflare|warp|vpn/.test(name)) return "globe.svg";
        if (/blueman|bluetooth/.test(name)) return "bluetooth.svg";
        if (/network/.test(name)) return "wifi.svg";
        if (/steam/.test(name)) return "gamepad.svg";
        return "app-windows.svg";
    }
}
