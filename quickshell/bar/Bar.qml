pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../common"

Item {
    id: root
    property int barWidth: Settings.barWidth
    readonly property bool horizontal: Settings.horizontalBar
    signal openPanel(var panel, var origin)
    Rectangle { anchors.fill: parent; color: Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, Settings.barOpacity) }
    Flickable {
        id: scroll
        anchors.fill: parent
        contentWidth: root.horizontal ? Math.max(width, rail.implicitWidth + 24) : width
        contentHeight: root.horizontal ? height : Math.max(height, rail.implicitHeight + 24)
        clip: true; boundsBehavior: Flickable.StopAtBounds
        flickableDirection: root.horizontal ? Flickable.HorizontalFlick : Flickable.VerticalFlick
        ScrollBar.vertical: ScrollBar { width: 3; policy: !root.horizontal && scroll.contentHeight > scroll.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff }
        ScrollBar.horizontal: ScrollBar { height: 3; policy: root.horizontal && scroll.contentWidth > scroll.width ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff }
        GridLayout {
            id: rail
            x: root.horizontal ? 12 : 0; y: root.horizontal ? 0 : 12
            columns: root.horizontal ? 3 : 1
            rowSpacing: 0; columnSpacing: 0
            width: root.horizontal ? Math.max(implicitWidth, scroll.width - 24) : scroll.width
            height: root.horizontal ? scroll.height : Math.max(implicitHeight, scroll.height - 24)
            Repeater {
                model: ["top", "middle", "bottom"]
                GridLayout {
                    id: zone
                    required property string modelData
                    Layout.fillWidth: true; Layout.fillHeight: true
                    columns: root.horizontal ? 3 : 1
                    rowSpacing: 0; columnSpacing: 0
                    Item { Layout.fillHeight: !root.horizontal; Layout.fillWidth: root.horizontal; visible: zone.modelData !== "top" }
                    GridLayout {
                        Layout.fillWidth: false; Layout.fillHeight: false
                        Layout.alignment: Qt.AlignCenter
                        columns: root.horizontal ? Math.max(1, Settings.barLayout[zone.modelData].length) : 1
                        columnSpacing: 8; rowSpacing: 8
                        Repeater {
                            model: Settings.barLayout[zone.modelData]
                            BarModule {
                                required property string modelData
                                moduleKey: modelData; horizontal: root.horizontal
                                railHeight: root.height
                                Layout.alignment: Qt.AlignCenter
                                onOpenPanel: (panel, origin) => root.openPanel(panel, origin)
                            }
                        }
                    }
                    Item { Layout.fillHeight: !root.horizontal; Layout.fillWidth: root.horizontal; visible: zone.modelData !== "bottom" }
                }
            }
        }
    }
}
