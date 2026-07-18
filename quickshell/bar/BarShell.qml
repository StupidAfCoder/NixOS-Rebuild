import QtQuick

Item {
    id: root
    property color surfaceColor: "#232939"

    Rectangle {
        anchors.fill: parent
        color: root.surfaceColor
        antialiasing: false
    }
}
