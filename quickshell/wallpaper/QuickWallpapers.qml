pragma Singleton
import QtQuick
import Quickshell.Io
Item {
    id: root
    property bool shown: false
    function open() { shown = true; WallpaperBackend.refresh(); }
    function toggle() { if (shown) hide(); else open(); }
    function hide() { shown = false; }
    IpcHandler { target: "quickwallpaper"; function toggle(): void { root.toggle(); } }
}
