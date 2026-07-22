import QtQuick
import Quickshell.Io

// Displays whatever PNG currently exists at `path`, and reloads it
// automatically whenever that file changes on disk (e.g. after
// generate-theme-assets.sh reruns following a theme change).
Item {
    id: root
    property string path: ""
    width: 24
    height: 24

    Image {
        id: img
        anchors.fill: parent
        smooth: false
        cache: false
        source: root.path === "" ? "" : "file://" + root.path
    }

    FileView {
        id: watcher
        path: root.path
        watchChanges: true
        onFileChanged: {
            // cache is off, so clearing then restoring source guarantees
            // a fresh decode from disk rather than reusing a stale result
            // for the same URL.
            img.source = ""
            img.source = "file://" + root.path
        }
    }
}
