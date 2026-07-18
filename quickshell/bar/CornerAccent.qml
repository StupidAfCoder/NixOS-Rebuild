import QtQuick

// Pixel-game corner bracket built from plain Rectangles only -- no
// Shape/PathSvg, so there's no path math to get subtly wrong. Two
// short arms (top + left) meeting at the true corner, each with a
// thin dark outline for a beveled pixel-art look, matching classic
// RPG dialog-box corner marks. Rotated per-corner so the same two
// arms sweep around to all four positions.
Item {
    id: root

    property int thickness: 4
    property real sizeScale: 4       // arm length = thickness * sizeScale
    property color color: "#565f89"
    property color outlineColor: "#11131c"
    property string corner: "topLeft"   // "topLeft" | "topRight" | "bottomLeft" | "bottomRight"
    property int hangOut: 0   // 0 = flush in corner. Positive = pulls it inward off the true corner, toward the border strip.

    property int armLength: Math.max(8, Math.round(thickness * sizeScale))
    property int armThickness: Math.max(2, Math.round(thickness * 0.6))

    width: armLength
    height: armLength

    rotation: corner === "topRight" ? 90
        : corner === "bottomRight" ? 180
        : corner === "bottomLeft" ? 270
        : 0
    transformOrigin: Item.Center

    transform: Translate {
        x: root.corner === "topLeft" || root.corner === "bottomLeft" ? root.hangOut : -root.hangOut
        y: root.corner === "topLeft" || root.corner === "topRight" ? root.hangOut : -root.hangOut
    }

    // --- Top arm: dark outline behind, colored fill on top ---
    Rectangle {
        x: 0; y: 0
        width: root.armLength
        height: root.armThickness + 2
        color: root.outlineColor
        antialiasing: false
    }
    Rectangle {
        x: 0; y: 1
        width: root.armLength - 1
        height: root.armThickness
        color: root.color
        antialiasing: false
    }

    // --- Left arm: dark outline behind, colored fill on top ---
    Rectangle {
        x: 0; y: 0
        width: root.armThickness + 2
        height: root.armLength
        color: root.outlineColor
        antialiasing: false
    }
    Rectangle {
        x: 1; y: 0
        width: root.armThickness
        height: root.armLength - 1
        color: root.color
        antialiasing: false
    }
}
