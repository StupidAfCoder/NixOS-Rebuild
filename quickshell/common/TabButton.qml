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
    checked: selected
}
