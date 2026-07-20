import QtQuick

// Pixel-game corner bracket, built entirely from axis-aligned
// Rectangles -- no rotation, no transform math. Each corner variant
// draws its own two arms in the correct orientation directly, so
// position is 100% controlled by anchors + anchors.margins at the
// call site (see ShellFrame.qml).
//
// Why the old version didn't align: QML applies the `transform` list
// BEFORE the item's own `rotation`. The old hangOut used a Translate
// in the `transform` list assuming pre-rotation coordinates, but
// topRight/bottomRight/bottomLeft then got rotated 90/180/270 AFTER
// that translate ran -- so the inward pull rotated out from under
// itself on 3 of 4 corners. This version has no rotation at all, so
// there's nothing to fight.
Item {
    id: root

    property int thickness: 4
    property real sizeScale: 10
    property color color: "#565f89"
    property color outlineColor: "#11131c"
    property string corner: "topLeft"   // "topLeft" | "topRight" | "bottomLeft" | "bottomRight"

    readonly property int armLength: Math.max(8, Math.round(thickness * sizeScale))
    readonly property int armThickness: Math.max(2, Math.round(thickness * 0.6))
    readonly property bool isRight: corner === "topRight" || corner === "bottomRight"
    readonly property bool isBottom: corner === "bottomLeft" || corner === "bottomRight"

    width: armLength
    height: armLength

    // --- horizontal arm: outline behind, fill in front ---
    Rectangle {
        x: 0
        y: root.isBottom ? root.armLength - root.armThickness - 2 : 0
        width: root.armLength
        height: root.armThickness + 2
        color: root.outlineColor
        antialiasing: false
    }
    Rectangle {
        x: root.isRight ? 1 : 0
        y: root.isBottom ? root.armLength - root.armThickness - 1 : 1
        width: root.armLength - 1
        height: root.armThickness
        color: root.color
        antialiasing: false
    }

    // --- vertical arm: outline behind, fill in front ---
    Rectangle {
        x: root.isRight ? root.armLength - root.armThickness - 2 : 0
        y: 0
        width: root.armThickness + 2
        height: root.armLength
        color: root.outlineColor
        antialiasing: false
    }
    Rectangle {
        x: root.isRight ? root.armLength - root.armThickness - 1 : 1
        y: root.isBottom ? 1 : 0
        width: root.armThickness
        height: root.armLength - 1
        color: root.color
        antialiasing: false
    }
}