import QtQuick
import Quickshell.Io

Image {
    id: root
    property string iconName: ""
    property color tint: "#c0caf5"
    readonly property string iconDir: "/home/swami/.local/share/pixelarticons/svg/"

    smooth: false

    FileView {
        id: fileLoader
        path: root.iconName === "" ? "" : (root.iconDir + root.iconName)
        blockLoading: true
    }

    source: {
        if (root.iconName === "") return ""
        var _dep = fileLoader.path   // keep this binding dependent on path so icon swaps re-trigger
        var svgText = fileLoader.text().replace(/currentColor/g, root.tint)
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgText)
    }
}