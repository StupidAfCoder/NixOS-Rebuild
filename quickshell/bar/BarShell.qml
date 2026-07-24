import QtQuick

Item {
    id: root
    property color surfaceColor: Colors.background

    Rectangle {
        anchors.fill: parent
        color: root.surfaceColor
        antialiasing: false
    }
}
