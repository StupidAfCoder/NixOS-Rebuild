import QtQuick
import Quickshell.Wayland
import "../common"

// Loaded by URL so an older Quickshell without ScreencopyView cannot prevent
// the entire shell from loading. Frames stay in memory, never on disk.
Item {
    id: root
    property var captureSource: null
    readonly property bool hasContent: feed.hasContent
    ScreencopyView {
        id: feed
        anchors.centerIn: parent
        width: implicitWidth; height: implicitHeight
        constraintSize: Qt.size(root.width, root.height)
        captureSource: root.captureSource
        live: !Settings.reducedMotion
        paintCursor: false
    }
}
