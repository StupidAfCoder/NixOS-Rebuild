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
    color: Colors.surface
    border.color: Colors.outlineVariant
    antialiasing: false
    Rectangle { width: 16; height: 2; x: 0; y: 0; color: Colors.accent }
    Rectangle { width: 2; height: 8; x: 0; y: 0; color: Colors.accent }
    ColumnLayout {
        id: layout
        x: 16; y: 16; width: parent.width - 32
        spacing: 14
        RowLayout {
            Layout.fillWidth: true; spacing: 10
            ColoredIcon { Layout.preferredWidth: 20; Layout.preferredHeight: 20; iconName: root.iconName; tint: Colors.accent }
            PixelText { text: root.title; font.family: "Silkscreen"; font.pixelSize: 11; Layout.fillWidth: true }
            PixelText { text: root.detail; visible: text.length > 0; color: Colors.textOnSurfaceVariant }
        }
        ColumnLayout { id: body; Layout.fillWidth: true; spacing: 12 }
    }
}
