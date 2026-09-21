import QtQuick
import QtQuick.Layouts
import "../bar"

Rectangle {
    id: root
    property string title: ""
    property string detail: ""
    property string iconName: "app-windows.svg"
    default property alias content: body.data
    implicitHeight: layout.implicitHeight + 32
    color: "transparent"
    border.width: 0
    antialiasing: false
    Rectangle { width: parent.width; height: 1; color: Colors.outlineVariant }
    ColumnLayout {
        id: layout
        x: 16; y: 16; width: parent.width - 32
        spacing: 14
        RowLayout {
            Layout.fillWidth: true; spacing: 10
            ColoredIcon { Layout.preferredWidth: 20; Layout.preferredHeight: 20; iconName: root.iconName; tint: Colors.accent }
            PixelText { text: root.title; font.family: "Silkscreen"; font.pixelSize: 11; Layout.fillWidth: true }
            PixelText { text: root.detail; visible: false; color: Colors.textOnSurfaceVariant }
        }
        ColumnLayout { id: body; Layout.fillWidth: true; spacing: 12 }
    }
}
