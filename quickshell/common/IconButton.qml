import QtQuick
import QtQuick.Controls
import "../bar"

PixelButton {
    id: root
    property string iconName: "app-windows.svg"
    property string hint: text
    implicitWidth: 32; implicitHeight: 32
    property int iconSize: Math.round(Math.max(16, Math.min(20, Settings.barWidth * .4)))
    padding: 4
    Accessible.name: hint
    background: Rectangle {
        color: root.down ? Colors.surfaceContainerHigh : root.hovered ? Colors.mix(Colors.background, Colors.accent, .16) : "transparent"
        Behavior on color { ColorAnimation { duration: Settings.motionMs } }
        border.width: root.visualFocus ? 1 : 0
        border.color: Colors.accent
        Rectangle { width: 2; height: 12; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; color: Colors.accent; visible: root.checked }
    }
    contentItem: Item {
        ColoredIcon { anchors.centerIn: parent; width: root.iconSize; height: root.iconSize; iconName: root.iconName; tint: Colors.accent; opacity: root.enabled ? 1 : .4 }
    }
}
