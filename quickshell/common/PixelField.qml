import QtQuick
import QtQuick.Controls
import "../bar"
TextField {
    id: root
    implicitHeight: 40
    padding: 10
    color: Colors.textOnBackground
    placeholderTextColor: Colors.textOnSurfaceVariant
    selectionColor: Colors.accent
    selectedTextColor: Colors.textOnAccent
    font.family: "Cozette"
    font.pixelSize: Settings.bodySize
    selectByMouse: true
    background: ConsoleSurface {
        raised: false
        fillColor: Colors.background
        edgeColor: root.activeFocus ? Colors.accent : Colors.outlineVariant
    }
}
