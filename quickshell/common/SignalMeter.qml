pragma ComponentBehavior: Bound
import QtQuick
import "../bar"
Row {
    id: root
    property int strength: 0
    spacing: 3
    Repeater {
        model: 4
        Rectangle {
            required property int index
            width: 4; height: 4 + index * 4; y: 16 - height
            color: root.strength > index * 25 ? Colors.accent : Colors.outlineVariant
        }
    }
}
