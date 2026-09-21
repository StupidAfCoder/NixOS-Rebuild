import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../bar"
import "../launcher"

Button {
    id: root
    property string label: ""
    property string detail: ""
    property url iconSource: ""
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
        border.width: root.visualFocus ? 1 : 0
        border.color: Colors.accent
        Rectangle { width: 2; height: 14; anchors.verticalCenter: parent.verticalCenter; color: Colors.accent; visible: root.selected }
    }
    contentItem: RowLayout {
        spacing: 14
        Item {
            visible: !!root.iconName || !!root.iconSource.toString(); Layout.preferredWidth: 24; Layout.preferredHeight: 24
            ColoredIcon { anchors.fill: parent; visible: !root.iconSource.toString(); iconName: root.iconName; tint: root.danger ? Colors.error : Colors.accent }
            PixelAppIcon { anchors.fill: parent; visible: !!root.iconSource.toString(); iconSource: root.iconSource }
        }
        ColumnLayout {
            Layout.fillWidth: true; spacing: 4
            PixelText { Layout.fillWidth: true; text: root.label; color: root.danger ? Colors.error : Colors.textOnBackground }
            PixelText { visible: !!root.detail; Layout.fillWidth: true; text: root.detail; color: Colors.textOnSurfaceVariant }
        }
        PixelText { visible: !!root.trailing; text: root.trailing; color: Colors.textOnSurfaceVariant }
    }
}
