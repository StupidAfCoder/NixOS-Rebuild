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
    contentItem: ColoredIcon { iconName: root.iconName; tint: root.primary ? Colors.textOnAccent : Colors.accent; opacity: root.enabled ? 1 : .4 }
    ToolTip.visible: hovered || activeFocus
    ToolTip.delay: 500
    ToolTip.text: hint
}
