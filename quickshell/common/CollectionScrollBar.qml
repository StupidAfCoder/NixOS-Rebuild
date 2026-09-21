import QtQuick
import "../bar"
import "ScrollGeometry.js" as ScrollGeometry

// Outside the GridView: nested ScrollView/Flickable gesture stealing must not
// turn a thumb drag into scrolling the whole sheet or a thumbnail click.
FocusScope {
    id: root
    required property Flickable target
    implicitWidth: 20
    activeFocusOnTab: true
    readonly property real trackHeight: Math.max(0, height - 8)
    readonly property real range: Math.max(0, target.contentHeight - target.height)
    readonly property real thumbHeight: ScrollGeometry.thumbSize(trackHeight, target.height, target.contentHeight)
    property real grabOffset: 0
    function seek(pointer) {
        target.contentY = ScrollGeometry.contentPosition(pointer - 4, grabOffset, trackHeight, thumbHeight, target.originY, range);
    }
    function step(amount) { target.cancelFlick(); target.contentY = ScrollGeometry.clamp(target.contentY + amount, target.originY, target.originY + range); }
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Up) step(-40);
        else if (event.key === Qt.Key_Down) step(40);
        else if (event.key === Qt.Key_PageUp) step(-target.height);
        else if (event.key === Qt.Key_PageDown) step(target.height);
        else if (event.key === Qt.Key_Home) step(-range);
        else if (event.key === Qt.Key_End) step(range);
        else { event.accepted = false; return; }
        event.accepted = true;
    }
    Rectangle { x: 8; y: 4; width: 4; height: root.trackHeight; color: Colors.outlineVariant }
    Rectangle {
        id: thumb
        x: 4; width: 12; height: root.thumbHeight
        y: 4 + (root.range > 0 ? ScrollGeometry.clamp((root.target.contentY - root.target.originY) / root.range, 0, 1) : 0) * (root.trackHeight - height)
        color: drag.pressed || drag.containsMouse || root.activeFocus ? Colors.accent : Colors.outline
        opacity: root.range > 0 ? 1 : .35
        Rectangle { anchors.centerIn: parent; width: 6; height: 2; color: Colors.background }
    }
    MouseArea {
        id: drag
        anchors.fill: parent
        hoverEnabled: true; preventStealing: true
        cursorShape: pressed ? Qt.SizeVerCursor : Qt.PointingHandCursor
        onPressed: event => {
            root.target.cancelFlick(); root.forceActiveFocus();
            root.grabOffset = event.y >= thumb.y && event.y <= thumb.y + thumb.height ? event.y - thumb.y : thumb.height / 2;
            root.seek(event.y);
        }
        onPositionChanged: event => { if (pressed) root.seek(event.y); }
        onWheel: event => { root.step(-(event.angleDelta.y / 120) * 120); event.accepted = true; }
    }
}
