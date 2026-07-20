import QtQuick
import QtQuick.Shapes
import "pathgen.js" as PathGen

// Seam divider: two rivet caps pinned near the true left/right ends,
// with a flat metal strip running behind/between them -- reads as a
// plate bolted down at both ends, not a cluster of parts in the middle.
Item {
    id: root
    property int barWidth: 32
    property int rivetSize: 8
    property int edgeMargin: 1      // how close each rivet sits to the true end -- keep this small
    property color rivetBorderColor: "#000000"
    property color rivetOuterColor: "#565b68"
    property color rivetShadowColor: "#101114"
    property color stripColor: "#2a2e42"
    property color stripBorderColor: "#000000"

    width: barWidth
    height: rivetSize + 6

    // --- Flat metal strip, spanning exactly between the two rivets ---
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: rivetLeft.x + rivetLeft.width
        width: Math.max(0, rivetRight.x - x)
        height: 3
        color: root.stripBorderColor
        antialiasing: false

        Rectangle {
            anchors.centerIn: parent
            width: Math.max(0, parent.width - 2)
            height: 1
            color: root.stripColor
            antialiasing: false
        }
    }

    Item {
        id: rivetLeft
        width: root.rivetSize
        height: root.rivetSize
        x: root.edgeMargin
        anchors.verticalCenter: parent.verticalCenter

        Shape {
            anchors.fill: parent
            antialiasing: false
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: root.rivetBorderColor
                strokeColor: "transparent"
                PathSvg { path: PathGen.chamferedRectPath(rivetLeft.width, rivetLeft.height, Math.round(rivetLeft.width / 3.5)) }
            }
        }
        Shape {
            anchors.fill: parent
            anchors.margins: 1
            antialiasing: false
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: root.rivetOuterColor
                strokeColor: "transparent"
                PathSvg { path: PathGen.chamferedRectPath(rivetLeft.width - 2, rivetLeft.height - 2, Math.round((rivetLeft.width - 2) / 3.5)) }
            }
        }
        Rectangle {
            anchors.centerIn: parent
            width: Math.max(2, root.rivetSize * 0.5)
            height: 1.5
            color: root.rivetShadowColor
            antialiasing: false
        }
    }

    Item {
        id: rivetRight
        width: root.rivetSize
        height: root.rivetSize
        x: root.width - root.rivetSize - root.edgeMargin
        anchors.verticalCenter: parent.verticalCenter

        Shape {
            anchors.fill: parent
            antialiasing: false
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: root.rivetBorderColor
                strokeColor: "transparent"
                PathSvg { path: PathGen.chamferedRectPath(rivetRight.width, rivetRight.height, Math.round(rivetRight.width / 3.5)) }
            }
        }
        Shape {
            anchors.fill: parent
            anchors.margins: 1
            antialiasing: false
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: root.rivetOuterColor
                strokeColor: "transparent"
                PathSvg { path: PathGen.chamferedRectPath(rivetRight.width - 2, rivetRight.height - 2, Math.round((rivetRight.width - 2) / 3.5)) }
            }
        }
        Rectangle {
            anchors.centerIn: parent
            width: Math.max(2, root.rivetSize * 0.5)
            height: 1.5
            color: root.rivetShadowColor
            antialiasing: false
        }
    }
}