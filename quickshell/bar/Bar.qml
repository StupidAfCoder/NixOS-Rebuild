pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../common"
import "../common/RailGeometry.js" as RailGeometry

Item {
    id: root
    property int barWidth: Settings.barWidth
    readonly property bool horizontal: Settings.horizontalBar
    property int layoutRevision: 0
    readonly property var arrangement: {
        const revision = layoutRevision;
        return RailGeometry.arrange(horizontal ? width : height,
            groupLength(0), groupLength(1), groupLength(2), 12, 16);
    }
    function groupLength(index) {
        const group = zones.itemAt(index);
        return group ? (horizontal ? group.implicitWidth : group.implicitHeight) : 0;
    }
    signal openPanel(var panel, var origin)
    signal workspaceHint(var origin)
    Rectangle { anchors.fill: parent; color: Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, Settings.barOpacity) }
    Flickable {
        id: scroll
        anchors.fill: parent
        contentWidth: root.horizontal ? root.arrangement.extent : width
        contentHeight: root.horizontal ? height : root.arrangement.extent
        clip: true; boundsBehavior: Flickable.StopAtBounds
        flickableDirection: root.horizontal ? Flickable.HorizontalFlick : Flickable.VerticalFlick
        ScrollBar.vertical: ScrollBar { width: 3; policy: !root.horizontal && scroll.contentHeight > scroll.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff }
        ScrollBar.horizontal: ScrollBar { height: 3; policy: root.horizontal && scroll.contentWidth > scroll.width ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff }
        Repeater {
            id: zones
            model: ["top", "middle", "bottom"]
            onItemAdded: root.layoutRevision++
            onItemRemoved: root.layoutRevision++
            GridLayout {
                id: zone
                required property string modelData
                required property int index
                x: root.horizontal ? root.arrangement.positions[index] : (scroll.width - width) / 2
                y: root.horizontal ? (scroll.height - height) / 2 : root.arrangement.positions[index]
                width: implicitWidth; height: implicitHeight
                columns: root.horizontal ? Math.max(1, Settings.barLayout[modelData].length) : 1
                columnSpacing: 8; rowSpacing: 8
                Repeater {
                    model: Settings.barLayout[zone.modelData]
                    BarModule {
                        required property string modelData
                        moduleKey: modelData; horizontal: root.horizontal
                        railHeight: root.height
                        Layout.alignment: Qt.AlignCenter
                        onOpenPanel: (panel, origin) => root.openPanel(panel, origin)
                        onWorkspaceHint: origin => root.workspaceHint(origin)
                    }
                }
            }
        }
    }
}
