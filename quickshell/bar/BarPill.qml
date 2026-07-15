import QtQuick
import QtQuick.Shapes
import "pathgen.js" as PathGen

Item {
    id: root
    property color fillColor: "#1a1b26"
    property color frameColor: "#000000"
    property int cornerCut: 6
    property int stairSteps: 2
    default property alias contentItem: contentSlot.children

    // --- Corner rivet caps ---
    property bool showRivets: false
    property int rivetSize: 12
    property real rivetPoke: 0.28              // fraction of rivetSize allowed to poke past the pill edge
    property color rivetAccentColor: "#7aa2f7" // outer contrast ring, matches active-workspace blue
    property color rivetBorderColor: "#000000"
    property color rivetOuterColor: "#4b505c"   // base steel
    property color rivetHighlightColor: "#c8ccd6" // upper-left light hit
    property color rivetShadowColor: "#1c1e23"    // lower-right shade
    property color rivetSlotColor: "#15161a"      // screw-slot mark

    // --- Reinforcement bracket plate behind each rivet ---
    property bool showBrackets: false
    property real bracketWidthScale: 0.75   // plate width relative to rivetSize (outward direction)
    property real bracketLengthScale: 2.4   // plate length relative to rivetSize (runs along the edge)
    property int bracketCornerCut: 3        // small chamfer, keeps it reading as rectangular hardware
    property color bracketColor: "#9aa0ad"
    property color bracketBorderColor: "#000000"
    property color bracketHighlightColor: "#c8ccd6"

    // --- Chain run connecting top and bottom rivets ---
    property bool showChain: false
    property int chainLinkSize: 12          // long-axis length of one link
    property real chainRingThickness: 2.5
    property color chainColor: "#8a8f9c"     // brighter than fill so it actually reads
    property color chainBorderColor: "#000000"
    property color chainHoleColor: root.fillColor

    readonly property real rivetEdgeOffset: Math.max(8, root.cornerCut * 0.65)
    // Vertical gap strictly between the inner edges of the top and bottom rivets
    readonly property real chainSpan: root.height - 2 * root.rivetEdgeOffset - 2 * root.rivetSize
    readonly property real chainStep: root.chainLinkSize * 0.55
    readonly property int chainLinkCount: root.showChain
        ? Math.max(0, Math.floor(root.chainSpan / root.chainStep) - 1)
        : 0

    width: 44
    height: 44

    Shape {
        id: frame
        anchors.fill: parent
        antialiasing: false
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.frameColor
            strokeColor: "transparent"
            PathSvg { path: PathGen.pixelStairPath(frame.width, frame.height, root.cornerCut, root.stairSteps) }
        }
    }

    Shape {
        id: inner
        anchors.fill: parent
        anchors.margins: 2
        antialiasing: false
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.fillColor
            strokeColor: "transparent"
            PathSvg { path: PathGen.pixelStairPath(inner.width, inner.height, Math.max(0, root.cornerCut - 2), root.stairSteps) }
        }
    }

    // --- Chain links: hollow interlocking rings, alternating vertical/horizontal
    // orientation like real chain links, overlapping so they read as connected
    // rather than a dotted line. ---
    Repeater {
        model: root.chainLinkCount
        delegate: Item {
            id: chainLink
            required property int index
            readonly property bool tall: index % 2 === 0   // alternate long axis
            readonly property real linkW: tall ? root.chainLinkSize * 0.55 : root.chainLinkSize
            readonly property real linkH: tall ? root.chainLinkSize : root.chainLinkSize * 0.55

            width: linkW
            height: linkH
            x: -linkW * 0.35
            y: root.rivetEdgeOffset + root.rivetSize + root.chainStep * 0.5 + index * root.chainStep

            // Outer border
            Rectangle {
                anchors.fill: parent
                color: root.chainBorderColor
                antialiasing: false
            }
            // Colored band
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                color: root.chainColor
                antialiasing: false
            }
            // Hollow hole - matches pill fill so the ring reads as open, not solid
            Rectangle {
                anchors.fill: parent
                anchors.margins: root.chainRingThickness
                color: root.chainHoleColor
                antialiasing: false
            }
        }
    }

    // --- Reinforcement bracket plates: rectangular straps the rivet mounts through ---
    Repeater {
        model: root.showBrackets ? [0, 1] : []   // 0 = top, 1 = bottom
        delegate: Item {
            id: bracket
            required property int modelData
            readonly property real plateW: root.rivetSize * root.bracketWidthScale
            readonly property real plateH: root.rivetSize * root.bracketLengthScale
            readonly property real rivetCenterY: modelData === 0
                ? root.rivetEdgeOffset + root.rivetSize / 2
                : root.height - root.rivetEdgeOffset - root.rivetSize / 2

            width: plateW
            height: plateH
            x: -plateW * 0.15   // mostly tucked under the pill edge, rivet pokes out further than plate
            y: rivetCenterY - plateH / 2

            // Border
            Shape {
                anchors.fill: parent
                antialiasing: false
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: root.bracketBorderColor
                    strokeColor: "transparent"
                    PathSvg { path: PathGen.chamferedRectPath(bracket.width, bracket.height, root.bracketCornerCut) }
                }
            }
            // Steel face
            Shape {
                anchors.fill: parent
                anchors.margins: 2
                antialiasing: false
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: root.bracketColor
                    strokeColor: "transparent"
                    PathSvg { path: PathGen.chamferedRectPath(bracket.width - 4, bracket.height - 4, Math.max(0, root.bracketCornerCut - 1)) }
                }
            }
            // Highlight strip down the outward-facing edge - sells "raised metal strap"
            Rectangle {
                x: bracket.width * 0.18
                y: bracket.height * 0.12
                width: Math.max(2, bracket.width * 0.18)
                height: bracket.height * 0.76
                color: root.bracketHighlightColor
                antialiasing: false
            }
        }
    }

    // --- Rivet caps: top-left and bottom-left, offset clear of the corner teeth ---
    Repeater {
        model: root.showRivets ? [0, 1] : []   // 0 = top, 1 = bottom
        delegate: Item {
            id: rivet
            required property int modelData

            width: root.rivetSize
            height: root.rivetSize
            x: -root.rivetSize * root.rivetPoke
            y: modelData === 0
               ? root.rivetEdgeOffset
               : root.height - root.rivetEdgeOffset - root.rivetSize

            // Outer accent ring - contrast pop against dark pill / busy wallpaper
            Shape {
                anchors.centerIn: parent
                width: parent.width + 2
                height: parent.height + 2
                antialiasing: false
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: root.rivetAccentColor
                    strokeColor: "transparent"
                    PathSvg { path: PathGen.chamferedRectPath(rivet.width + 2, rivet.height + 2, Math.round((rivet.width + 2) / 3.5)) }
                }
            }

            // Black border ring
            Shape {
                anchors.fill: parent
                antialiasing: false
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: root.rivetBorderColor
                    strokeColor: "transparent"
                    PathSvg { path: PathGen.chamferedRectPath(rivet.width, rivet.height, Math.round(rivet.width / 3.5)) }
                }
            }

            // Base steel face, inset 2px from border
            Shape {
                anchors.fill: parent
                anchors.margins: 2
                antialiasing: false
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: root.rivetOuterColor
                    strokeColor: "transparent"
                    PathSvg { path: PathGen.chamferedRectPath(rivet.width - 4, rivet.height - 4, Math.round((rivet.width - 4) / 3.5)) }
                }
            }

            // Shadow chip, lower-right - fakes a domed cap
            Rectangle {
                x: parent.width * 0.42
                y: parent.height * 0.42
                width: parent.width * 0.4
                height: parent.height * 0.4
                color: root.rivetShadowColor
                antialiasing: false
            }

            // Highlight chip, upper-left
            Rectangle {
                x: parent.width * 0.18
                y: parent.height * 0.18
                width: parent.width * 0.32
                height: parent.height * 0.32
                color: root.rivetHighlightColor
                antialiasing: false
            }

            // Screw-slot mark, dead center, on top of everything
            Rectangle {
                anchors.centerIn: parent
                width: Math.max(3, root.rivetSize * 0.55)
                height: 2
                color: root.rivetSlotColor
                antialiasing: false
            }

            MouseArea {
                anchors.fill: parent
                // placeholder - wire up real behavior later
                onClicked: console.log("rivet clicked: " + (rivet.modelData === 0 ? "top" : "bottom"))
            }
        }
    }

    Item {
        id: contentSlot
        anchors.fill: parent
    }
}
