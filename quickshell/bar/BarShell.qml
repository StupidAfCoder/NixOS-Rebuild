import QtQuick

Item {
    id: root
    property color surfaceColor: Colors.background

    Rectangle {
        anchors.fill: parent
        color: root.surfaceColor
        antialiasing: false
        Behavior on color { ColorAnimation { duration: 350; easing.type: Easing.OutCubic } }
    }
}
