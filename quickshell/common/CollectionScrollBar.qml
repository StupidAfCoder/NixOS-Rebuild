import QtQuick
import QtQuick.Controls
import "../bar"

ScrollBar {
    id: root
    policy: ScrollBar.AlwaysOn
    interactive: true
    minimumSize: .08
    implicitWidth: 10
    padding: 2
    contentItem: Rectangle {
        implicitWidth: 6; implicitHeight: 24
        color: root.pressed || root.hovered ? Colors.accent : Colors.outline
    }
    background: Rectangle { color: Colors.surfaceContainerHigh }
}
