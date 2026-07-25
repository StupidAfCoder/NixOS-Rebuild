import QtQuick
import QtQuick.Layouts

Item {
    id: row
    property string label: ""
    property string iconName: ""
    property color accent: Colors.accent
    signal clicked

    Layout.preferredHeight: 26

    Rectangle {
        anchors.fill: parent
        color: mouseArea.containsMouse ? Colors.surfaceContainer : "transparent"
        antialiasing: false
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 6
        spacing: 4

        Text {
            text: "\u25b6"
            color: row.accent
            font.pixelSize: 8
            opacity: mouseArea.containsMouse ? 1.0 : 0.0
            Layout.preferredWidth: 10

            Behavior on opacity { NumberAnimation { duration: 100 } }
        }

        ColoredIcon {
            Layout.preferredWidth: 11
            Layout.preferredHeight: 11
            iconName: row.iconName
            tint: mouseArea.containsMouse ? row.accent : Colors.mutedOnBackground
        }

        Text {
            text: row.label
            color: mouseArea.containsMouse ? row.accent : Colors.mutedOnBackground
            font.family: "Cozette"
            font.pixelSize: 9
            font.letterSpacing: 1
            Layout.fillWidth: true
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: row.clicked()
        z: 5
    }
}