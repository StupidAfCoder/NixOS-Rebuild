import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../bar"

Button {
    id: root
    property string label: ""
    property string detail: ""
    property string iconName: ""
    property string trailing: ""
    property bool selected: false
    property bool danger: false
    implicitHeight: detail ? 62 : 46
    implicitWidth: 240
    padding: 12
    hoverEnabled: true
    Accessible.name: label + (detail ? ", " + detail : "")
    background: Rectangle {
        color: root.down || root.selected ? Colors.surfaceContainerHigh : root.hovered ? Colors.surfaceContainer : "transparent"
        border.width: root.activeFocus ? 1 : 0
        border.color: Colors.accent
        Rectangle { width: 2; height: 14; anchors.verticalCenter: parent.verticalCenter; color: Colors.accent; visible: root.selected }
    }
    contentItem: RowLayout {
        spacing: 14
        ColoredIcon { visible: !!root.iconName; Layout.preferredWidth: 22; Layout.preferredHeight: 22; iconName: root.iconName; tint: root.danger ? Colors.error : Colors.accent }
        ColumnLayout {
            Layout.fillWidth: true; spacing: 4
            PixelText { Layout.fillWidth: true; text: root.label; color: root.danger ? Colors.error : Colors.textOnBackground }
            PixelText { visible: !!root.detail; Layout.fillWidth: true; text: root.detail; color: Colors.textOnSurfaceVariant }
        }
        PixelText { visible: !!root.trailing; text: root.trailing; color: Colors.textOnSurfaceVariant }
    }
}
