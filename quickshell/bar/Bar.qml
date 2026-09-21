pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../common"

Item {
    id: root
    property int barWidth: Settings.barWidth
    signal openPanel(var panel, var origin)
    width: barWidth
    Rectangle { anchors.fill: parent; color: Colors.background }
    // Hidden modules are absent from the layout, not transparent placeholders.
    Flickable {
        id: scroll
        anchors.fill: parent
        contentWidth: width; contentHeight: Math.max(height, rail.implicitHeight + 24)
        clip: true; boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        ScrollBar.vertical: ScrollBar { width: 3; policy: scroll.contentHeight > scroll.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff }
        ColumnLayout {
            id: rail
            y: 12; width: parent.width; height: Math.max(implicitHeight, scroll.height - 24)
            spacing: 0
            Repeater {
                model: ["top", "middle", "bottom"]
                ColumnLayout {
                    id: zone
                    required property string modelData
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0
                    Item { Layout.fillHeight: true; visible: zone.modelData !== "top" }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 8
                        Repeater {
                            model: Settings.barLayout[zone.modelData]
                            BarModule {
                                required property string modelData
                                moduleKey: modelData
                                railHeight: root.height
                                Layout.alignment: Qt.AlignHCenter
                                onOpenPanel: (panel, origin) => root.openPanel(panel, origin)
                            }
                        }
                    }
                    Item { Layout.fillHeight: true; visible: zone.modelData !== "bottom" }
                }
            }
        }
    }
}
