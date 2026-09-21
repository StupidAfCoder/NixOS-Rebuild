import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../bar"
import "PopupGeometry.js" as Placement

// A bounded, keyboard-accessible popup. Content scrolls; title and close stay reachable.
FocusScope {
    id: root
    property bool shown: false
    property string title: ""
    property string subtitle: ""
    property int preferredWidth: 380
    property int preferredHeight: 500
    property bool centered: false
    // Window-local origin captured at the bar click; IPC opens use -1.
    property real anchorY: -1
    property real anchorX: -1
    readonly property var area: Placement.bounds(parent.width, parent.height, Settings.desktopInsets, 12)
    readonly property var placement: Placement.panelPosition(area, width, height, Settings.barEdge, centered, anchorX, anchorY)
    property bool fitContent: true
    property int contentPadding: 16
    property Item initialFocusItem: root
    function resetScroll() { scroller.contentItem.contentY = 0; }
    // Empty = popup. Four edge directions translate without scaling pixel text.
    property string edge: ""
    property real reveal: shown ? 1 : 0
    default property alias content: body.data
    signal dismiss()
    width: Math.max(1, Math.min(preferredWidth, area.width))
    height: Math.max(1, Math.min(preferredHeight, fitContent ? body.implicitHeight + heading.implicitHeight + 1 + 24 + contentPadding * 2 : preferredHeight, area.height))
    x: edge === "right" ? area.x + area.width - width + (width + Settings.desktopInsets.right + 12) * (1 - reveal)
       : edge === "left" ? area.x - (width + area.x) * (1 - reveal) : placement.x
    y: edge === "top" ? area.y - (height + area.y) * (1 - reveal)
       : edge === "bottom" ? area.y + area.height - height + (height + Settings.desktopInsets.bottom + 12) * (1 - reveal) : placement.y
    z: 20
    visible: shown || reveal > 0
    enabled: shown
    opacity: edge ? 1 : reveal
    Behavior on reveal { NumberAnimation { duration: Settings.motionMs; easing.type: Easing.OutCubic } }
    Timer {
        id: focusLater; interval: 0
        onTriggered: if (root.shown && root.initialFocusItem) root.initialFocusItem.forceActiveFocus()
    }
    Connections {
        target: root
        function onShownChanged() { if (root.shown) focusLater.restart(); else focusLater.stop(); }
    }
    Keys.onEscapePressed: event => { root.dismiss(); event.accepted = true; }
    ConsoleSurface { anchors.fill: parent; fillColor: Colors.surfaceContainerLow; edgeColor: Colors.outlineVariant; raised: false }
    Rectangle { x: 0; y: 0; width: 18; height: 2; color: Colors.accent }
    MouseArea { anchors.fill: parent; onClicked: {} }
    ColumnLayout {
        anchors.fill: parent; anchors.margins: root.contentPadding; spacing: 12
        RowLayout {
            id: heading
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true; spacing: 4
                PixelText { text: root.title; font.family: "Silkscreen"; font.pixelSize: 14; Layout.fillWidth: true }
                PixelText { text: root.subtitle; visible: text.length > 0; color: Colors.textOnSurfaceVariant; Layout.fillWidth: true }
            }
            IconButton { iconName: "close.svg"; hint: "Close"; onClicked: root.dismiss() }
        }
        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Colors.outlineVariant }
        ScrollView {
            id: scroller
            Layout.fillWidth: true; Layout.fillHeight: true
            clip: true; contentWidth: availableWidth
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ColumnLayout {
                id: body
                width: scroller.availableWidth
                spacing: 12
            }
        }
    }
}
