import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property string iconName: ""
    property string label: ""
    signal triggered()

    width: 44
    height: 52

    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        Image {
            Layout.alignment: Qt.AlignHCenter
            width: 20
            height: 20
            smooth: false
            source: "file:///home/swami/.local/share/pixelarticons/svg/" + root.iconName
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.label
            color: "#c0caf5"
            font.family: "Cozette"
            font.pixelSize: 9
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.triggered()
    }
}