import QtQuick
import QtQuick.Layouts

Rectangle {
    id: btn
    property string label: ""
    property string iconName: ""
    property color accent: "#7aa2f7"
    signal clicked

    Layout.preferredHeight: 32
    color: mouseArea.containsMouse ? Qt.darker(accent, 3.2) : "transparent"
    border.color: mouseArea.containsMouse ? accent : "#414868"
    border.width: 1
    antialiasing: false

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 8

        ColoredIcon {
            Layout.preferredWidth: 12
            Layout.preferredHeight: 12
            iconName: btn.iconName
            tint: mouseArea.containsMouse ? btn.accent : "#a9b1d6"
        }

        Text {
            text: btn.label
            color: mouseArea.containsMouse ? btn.accent : "#c0caf5"
            font.family: "Cozette"
            font.pixelSize: 9
            Layout.fillWidth: true
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}