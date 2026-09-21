import QtQuick
import "../bar"
Text {
    color: Colors.textOnBackground
    font.family: "Cozette"
    font.pixelSize: Settings.bodySize
    renderType: Text.NativeRendering
    textFormat: Text.PlainText
    elide: Text.ElideRight
}
