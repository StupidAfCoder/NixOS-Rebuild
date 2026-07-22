import QtQuick

// Plays a frame-stepped animation from a horizontal sprite sheet,
// swapping between two pre-baked (already colored) sheets on hover.
Item {
    id: root
    property string accentSource: ""
    property string hoverSource: ""
    property bool hovered: false
    property int frameW: 24
    property int frameH: 24
    property int frameCount: 1
    property int fps: 8
    property bool playing: true

    property int currentFrame: 0
    width: frameW
    height: frameH

    Image {
        id: sheet
        anchors.fill: parent
        smooth: false
        source: root.hovered ? root.hoverSource : root.accentSource
        sourceClipRect: Qt.rect(root.currentFrame * root.frameW, 0, root.frameW, root.frameH)
    }

    Timer {
        interval: 1000 / root.fps
        running: root.playing && root.frameCount > 1
        repeat: true
        onTriggered: root.currentFrame = (root.currentFrame + 1) % root.frameCount
    }
}
