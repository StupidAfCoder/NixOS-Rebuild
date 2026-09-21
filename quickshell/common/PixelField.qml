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
    background: Rectangle {
        color: Colors.background
        border.color: root.activeFocus ? Colors.accent : Colors.outlineVariant
        border.width: root.activeFocus ? 2 : 1
    }
}
