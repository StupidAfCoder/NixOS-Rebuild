import QtQuick
import Quickshell.Widgets

// Renders any icon at a low resolution then stretches it back up with
// smooth: false — real nearest-neighbour pixelation, not a fake filter.
// Lower pixelSize = blockier/more retro.
Item {
    id: root

    property string iconSource: ""
    property int pixelSize: 10
    property int displaySize: 48
    property color gridTint: "#000000"
    property real gridOpacity: 0.10

    implicitWidth: displaySize
    implicitHeight: displaySize

    IconImage {
        id: icon
        anchors.fill: parent
        source: root.iconSource
        smooth: false
        asynchronous: true
        implicitSize: root.pixelSize
    }

    // subtle pixel-grid overlay so it reads as "pixel art" even when
    // the underlying icon is a smooth SVG blown down and back up
    Canvas {
        id: grid
        anchors.fill: parent
        opacity: root.gridOpacity
        renderStrategy: Canvas.Cooperative

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.strokeStyle = root.gridTint
            ctx.lineWidth = 1
            var stepX = width / root.pixelSize
            var stepY = height / root.pixelSize
            for (var i = 1; i < root.pixelSize; i++) {
                ctx.beginPath()
                ctx.moveTo(i * stepX, 0)
                ctx.lineTo(i * stepX, height)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(0, i * stepY)
                ctx.lineTo(width, i * stepY)
                ctx.stroke()
            }
        }
    }
}