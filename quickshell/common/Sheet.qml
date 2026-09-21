import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../bar"

// A bounded, keyboard-accessible popup. Content scrolls; title and close stay reachable.
FocusScope {
    id: root
    property bool shown: false
    property string title: ""
    property string subtitle: ""
    property int preferredWidth: 380
    property int preferredHeight: 500
    property bool centered: false
    property Item initialFocusItem: root
    // Empty = ordinary popup. Right/left = sliding edge drawer, in the same layer window.
    property string edge: ""
    property real reveal: shown ? 1 : 0
    default property alias content: body.data
    signal dismiss()
    width: Math.max(1, Math.min(preferredWidth, parent.width - Settings.barWidth - 36))
    height: Math.max(1, Math.min(preferredHeight, parent.height - Settings.frameWidth * 2 - 32))
    x: edge === "right" ? parent.width - (width + Settings.frameWidth + 12) * reveal
       : edge === "left" ? Settings.barWidth + 12 - (width + Settings.barWidth + 12) * (1 - reveal)
       : centered ? Settings.barWidth + (parent.width - Settings.barWidth - width) / 2 : Settings.barWidth + 12
    y: Math.round((parent.height - height) / 2)
    z: 20
    visible: shown || reveal > 0
    enabled: shown
    opacity: edge ? 1 : reveal
    Behavior on reveal { NumberAnimation { duration: Settings.motionMs; easing.type: Easing.OutCubic } }
    Connections {
        target: root
        function onShownChanged() { if (root.shown) Qt.callLater(function() { if (root.shown && root.initialFocusItem) root.initialFocusItem.forceActiveFocus(); }); }
    }
    Keys.onEscapePressed: event => { root.dismiss(); event.accepted = true; }
    Rectangle { anchors.fill: parent; color: Colors.surfaceContainerLow; border.color: Colors.outlineVariant; antialiasing: false }
    Rectangle { x: 0; y: 0; width: 5; height: 5; color: Colors.background }
    Rectangle { anchors.right: parent.right; anchors.bottom: parent.bottom; width: 5; height: 5; color: Colors.background }
    MouseArea { anchors.fill: parent; onClicked: {} }
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 20; spacing: 16
        RowLayout {
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
