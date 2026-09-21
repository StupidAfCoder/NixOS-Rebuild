import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../bar"

RowLayout {
    id: root
    property string label: ""
    property string description: ""
    property string iconName: "settings-2.svg"
    property bool selected: false
    signal toggled()
    spacing: 12
    ColoredIcon { Layout.preferredWidth: 22; Layout.preferredHeight: 22; iconName: root.iconName; tint: root.selected ? Colors.accent : Colors.textOnSurfaceVariant }
    ColumnLayout {
        Layout.fillWidth: true; spacing: 4
        PixelText { text: root.label; Layout.fillWidth: true; wrapMode: Text.Wrap; elide: Text.ElideNone }
        PixelText { text: root.description; visible: text.length > 0; Layout.fillWidth: true; wrapMode: Text.Wrap; elide: Text.ElideNone; color: Colors.textOnSurfaceVariant }
    }
    PixelButton {
        text: root.selected ? "On" : "Off"
        primary: root.selected
        Accessible.name: root.label + ": " + text
        onClicked: root.toggled()
    }
}
