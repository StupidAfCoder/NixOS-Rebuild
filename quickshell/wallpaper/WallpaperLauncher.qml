pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    property bool shown: false
    property string requestedPath: ""
    // Global close only: moving this drawer between monitors must not cancel
    // the new screen's request because the old content instance became hidden.
    onShownChanged: if (!shown) WallpaperBackend.cancelPreview()
    function openFor(path) { requestedPath = path; shown = true; WallpaperBackend.refresh(); }

    function toggle() {
        shown = !shown;
        if (shown)
            WallpaperBackend.refresh();
    }
    function hide() {
        shown = false;
    }

    IpcHandler {
        target: "wallpaper"
        function toggle(): void {
            root.toggle();
        }
    }
}
