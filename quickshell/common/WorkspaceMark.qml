pragma ComponentBehavior: Bound
import QtQuick
import "../bar"

// Seven-pixel save gems: outline = empty, core = occupied, full = active.
Item {
    id: root
    property bool active: false
    property bool occupied: false
    property color tint: Colors.accent
    implicitWidth: 14; implicitHeight: 14
    readonly property var rows: active ? ["0001000", "0011100", "0111110", "1111111", "0111110", "0011100", "0001000"]
        : occupied ? ["0001000", "0010100", "0101010", "1011101", "0101010", "0010100", "0001000"]
        : ["0001000", "0010100", "0100010", "1000001", "0100010", "0010100", "0001000"]
    Repeater {
        model: 49
        Rectangle {
            required property int index
            x: (index % 7) * root.width / 7; y: Math.floor(index / 7) * root.height / 7
            width: root.width / 7; height: root.height / 7
            visible: root.rows[Math.floor(index / 7)][index % 7] === "1"
            color: root.tint
            opacity: root.active ? 1 : root.occupied ? .8 : .55
        }
    }
}
