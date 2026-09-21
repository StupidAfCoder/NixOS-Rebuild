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
    quiet: true
    contentItem: Item {
        ColoredIcon { anchors.centerIn: parent; width: root.iconSize; height: root.iconSize; iconName: root.iconName; tint: Colors.accent; opacity: root.enabled ? 1 : .4 }
    }
}
