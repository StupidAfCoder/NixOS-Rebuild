import QtQuick
import QtQuick.Layouts
import "../bar"

Rectangle {
    id: root
    property string iconName: "wifi.svg"
    property string status: ""
    property string heading: ""
    property string detail: ""
    property bool online: false
    property bool searching: false
    implicitHeight: 164
    color: Colors.surface
    border.color: Colors.outlineVariant
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 18; spacing: 12
        RowLayout {
            spacing: 8; Layout.fillWidth: true
            Rectangle {
                implicitWidth: 5; implicitHeight: 5
                color: root.online || root.searching ? Colors.accent : Colors.outline
                SequentialAnimation on opacity { running: root.searching && root.visible && !Settings.reducedMotion; loops: Animation.Infinite; NumberAnimation { to: .35; duration: 600 } NumberAnimation { to: 1; duration: 600 } }
            }
            PixelText { text: root.status; font.family: "Silkscreen"; font.pixelSize: 10; color: Colors.textOnSurfaceVariant; Layout.fillWidth: true }
        }
        RowLayout {
            Layout.fillWidth: true; spacing: 16
            ColoredIcon { iconName: root.iconName; tint: Colors.accent; Layout.preferredWidth: 30; Layout.preferredHeight: 30 }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 6
                PixelText { text: root.heading; font.family: "Pixel Operator"; font.pixelSize: 23; Layout.fillWidth: true }
                PixelText { text: root.detail; color: Colors.textOnSurfaceVariant; Layout.fillWidth: true; wrapMode: Text.Wrap; elide: Text.ElideNone }
            }
        }
    }
    Rectangle { width: 20; height: 2; color: Colors.accent; anchors.left: parent.left; anchors.bottom: parent.bottom }
}
