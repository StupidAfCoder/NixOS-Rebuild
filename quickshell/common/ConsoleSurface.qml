import QtQuick
import "../bar"

// Two-pixel cut corners and a one-pixel keycap lip. Rectangles keep the edge
// crisp without a shader, shadow blur or rounded-card antialiasing.
Item {
    id: root
    property color fillColor: Colors.surfaceContainer
    property color edgeColor: Colors.outlineVariant
    property bool pressed: false
    property bool raised: true
    property bool lit: false
    Rectangle { x: 2; y: 2; width: Math.max(0, parent.width - 4); height: Math.max(0, parent.height - 2); color: Colors.shadow; visible: root.raised }
    Item {
        x: 0; y: root.raised && root.pressed ? 2 : 0
        width: parent.width; height: Math.max(0, parent.height - (root.raised ? 2 : 0))
        Rectangle { x: 2; width: Math.max(0, parent.width - 4); height: parent.height; color: root.edgeColor }
        Rectangle { y: 2; width: parent.width; height: Math.max(0, parent.height - 4); color: root.edgeColor }
        Rectangle { x: 3; y: 1; width: Math.max(0, parent.width - 6); height: Math.max(0, parent.height - 2); color: root.fillColor }
        Rectangle { x: 1; y: 3; width: Math.max(0, parent.width - 2); height: Math.max(0, parent.height - 6); color: root.fillColor }
        Rectangle { x: 4; y: 1; width: Math.max(0, parent.width - 8); height: 1; visible: root.raised && !root.pressed; color: Colors.mix(root.fillColor, root.lit ? Colors.accent : Colors.textOnSurface, .25) }
    }
}
