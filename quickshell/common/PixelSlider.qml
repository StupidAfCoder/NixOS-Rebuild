import QtQuick
import QtQuick.Controls
import "../bar"
Slider {
    id: root
    implicitHeight: 32
    background: Rectangle {
        x: root.leftPadding; y: root.topPadding + root.availableHeight / 2 - height / 2
        implicitHeight: 4; width: root.availableWidth; height: implicitHeight
        color: Colors.outlineVariant
        Rectangle { width: root.visualPosition * parent.width; height: parent.height; color: Colors.accent }
    }
    handle: ConsoleSurface {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: 14; height: 20; fillColor: Colors.accent
        edgeColor: root.visualFocus ? Colors.textOnBackground : Colors.outline
        pressed: root.pressed
    }
}
