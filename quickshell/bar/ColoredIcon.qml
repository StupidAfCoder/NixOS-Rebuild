import QtQuick
import Quickshell.Io

Image {
    id: root
    property string iconName: ""
    property color tint: Colors.onSurface

    readonly property string primaryDir: "/home/swami/.local/share/pixelarticons/svg/"
    readonly property string overrideDir: Qt.resolvedUrl("assets/")

    // Icons that don't exist upstream and live in bar/assets/ instead.
    // Add to this list any time you vendor a new custom icon.
    readonly property var overrides: ["bluetooth.svg", "bluetooth-connected.svg", "bluetooth-off.svg"]

    readonly property string activeDir: overrides.indexOf(iconName) !== -1 ? overrideDir : primaryDir

    smooth: false

    FileView {
        id: fileLoader
        path: root.iconName === "" ? "" : (root.activeDir + root.iconName)
        blockLoading: true
    }

    source: {
        if (root.iconName === "") return ""
        var _dep = fileLoader.path   // keep this binding dependent on path so icon swaps re-trigger
        var svgText = fileLoader.text().replace(/currentColor/g, root.tint)
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgText)
    }
}