import QtQuick
import QtQuick.Controls
import "../bar"
Button {
    id: root
    property bool primary: false
    property bool danger: false
    implicitHeight: 36
    implicitWidth: Math.max(36, label.implicitWidth + 24)
    padding: 10
    hoverEnabled: true
    font.family: "Cozette"
    font.pixelSize: Settings.bodySize
    contentItem: PixelText {
        id: label
        text: root.text
        font: root.font
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: (root.primary || root.checked) ? Colors.textOnAccent : root.danger ? Colors.error : Colors.textOnBackground
        opacity: root.enabled ? 1 : 0.45
    }
    background: Rectangle {
        color: (root.primary || root.checked) ? Colors.accent : root.down || root.hovered ? Colors.surfaceContainerHigh : "transparent"
        border.width: root.activeFocus ? 1 : 0
        border.color: root.activeFocus || root.hovered || root.checked ? Colors.accent : Colors.outlineVariant
        antialiasing: false
    }
}
