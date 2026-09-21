import QtQuick
import Quickshell
import Quickshell.Io

Image {
    id: root
    property string iconName: "app-windows.svg"
    property color tint: Colors.textOnBackground
    readonly property string iconDir: Quickshell.shellPath("bar/assets/icons/")
    readonly property string fallback: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M4 4h16v16H4V4zm2 2v12h12V6H6zm3 3h6v6H9z"/></svg>'
    property string svgData: fallback
    smooth: false
    fillMode: Image.PreserveAspectFit
    onIconNameChanged: svgData = fallback
    FileView {
        id: file
        path: root.iconName ? root.iconDir + root.iconName.replace(/[^a-zA-Z0-9_.-]/g, "") : ""
        preload: true
        onLoaded: { const svg = text(); root.svgData = svg.indexOf("<svg") >= 0 ? svg : root.fallback; }
        onLoadFailed: root.svgData = root.fallback
    }
    // Pure binding: never initiate I/O or change a dependency while evaluating source.
    source: iconName ? "data:image/svg+xml;utf8," + encodeURIComponent(svgData.replace(/currentColor/g, tint)) : ""
}
