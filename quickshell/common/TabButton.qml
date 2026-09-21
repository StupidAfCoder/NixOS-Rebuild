import QtQuick
import "../bar"
PixelButton {
    id: root
    property bool selected: false
    padding: 8
    font.family: "Silkscreen"
    font.pixelSize: 10
    Accessible.role: Accessible.PageTab
    Accessible.name: text
    contentItem: PixelText {
        text: root.text; font: root.font
        color: root.selected ? Colors.accent : Colors.textOnSurfaceVariant
        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
    }
    background: Item {
        Rectangle { height: 2; width: parent.width; anchors.bottom: parent.bottom; color: Colors.accent; visible: root.selected }
        Rectangle { anchors.fill: parent; color: "transparent"; border.color: Colors.accent; visible: root.activeFocus }
    }
}
