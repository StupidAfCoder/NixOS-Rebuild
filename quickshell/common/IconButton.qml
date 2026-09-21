import QtQuick
import QtQuick.Controls
import "../bar"

PixelButton {
    id: root
    property string iconName: "app-windows.svg"
    property string hint: text
    implicitWidth: 32; implicitHeight: 32
    padding: 4
    Accessible.name: hint
    background: Rectangle {
        color: root.down ? Colors.surfaceContainerHigh : "transparent"
        border.width: root.activeFocus ? 1 : 0
        border.color: Colors.accent
        Rectangle { width: 2; height: 12; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; color: Colors.accent; visible: root.checked }
    }
    contentItem: ColoredIcon { iconName: root.iconName; tint: root.primary || root.checked ? Colors.accent : Colors.textOnSurfaceVariant; opacity: root.enabled ? 1 : .4 }
}
