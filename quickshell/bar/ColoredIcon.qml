import QtQuick
import Quickshell.Io

Image {
    id: root
    property string iconName: "app-windows.svg"
    property color tint: Colors.textOnBackground
    readonly property string iconDir: decodeURIComponent(Qt.resolvedUrl("assets/icons/").toString().replace("file://", ""))
    // Geometric fallback: never an empty box or a missing-font glyph.
    readonly property string fallback: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M3 3h18v18H3V3zm2 2v14h14V5H5zm3 3h8v2H8zm0 5h8v2H8z"/></svg>'
    property int revision: 0
    smooth: false
    fillMode: Image.PreserveAspectFit
    FileView {
        id: file
        path: root.iconName ? root.iconDir + root.iconName.replace(/[^a-zA-Z0-9_.-]/g, "") : ""
        blockLoading: true
        onLoaded: root.revision++
        onLoadFailed: root.revision++
    }
    source: {
        if (!root.iconName) return "";
        const dependency = root.revision + file.path;
        const data = file.text();
        const svg = data.indexOf("<svg") >= 0 ? data : root.fallback;
        return "data:image/svg+xml;utf8," + encodeURIComponent(svg.replace(/currentColor/g, root.tint));
    }
}
