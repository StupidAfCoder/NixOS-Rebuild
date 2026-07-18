import Quickshell
import Quickshell.Wayland
import QtQuick
import "."

// Why this file exists (read this before touching seam/corner code):
//
// The old setup used FOUR separate layer-shell windows (left bar, top
// border, bottom border, right border), each independently positioned
// with hand-computed margins, plus "seam stub" rectangles trying to
// paper over the gap between them. That's fighting the compositor:
// four different Wayland surfaces will never share a coordinate space
// perfectly, so the seam between the bar and the border was always
// one rounding error away from cracking.
//
// caelestia-shell solves this by never having a seam to align in the
// first place: it draws its bar + border as ONE window per screen
// (ContentWindow) that sets exclusionMode: ExclusionMode.Ignore so it
// can paint over the *entire* output ignoring layer-shell exclusion
// zones, then uses a second, purely invisible set of windows
// (Exclusions.qml) just to reserve strut space with the compositor so
// normal app windows don't get covered. The visible bar and the
// visible border are literally the same Item tree in the same window
// -- there is nothing left to misalign.
//
// This file reproduces that pattern: `frame` below is the one and
// only surface that draws pixels, and `struts` below reserve layout
// space but draw nothing.
Scope {
    id: manager

    property int barWidth: 32
    property int borderThickness: 4
    property color frameColor: "#232939"
    property color accentColor: "#565f89"

    Variants {
        model: Quickshell.screens

        delegate: Component {
            Item {
                id: screenRoot
                required property var modelData

                // === Struts: invisible, exclusiveZone-only windows ===
                // These exist purely so Hyprland reserves space for the
                // bar + border and doesn't let maximized/tiled windows
                // slide underneath them. They render nothing.
                PanelWindow {
                    screen: screenRoot.modelData
                    WlrLayershell.layer: WlrLayer.Top
                    WlrLayershell.namespace: "quickshell:strut-left"
                    anchors { top: true; bottom: true; left: true }
                    implicitWidth: manager.barWidth
                    exclusiveZone: manager.barWidth
                    color: "transparent"
                }
                PanelWindow {
                    screen: screenRoot.modelData
                    WlrLayershell.layer: WlrLayer.Top
                    WlrLayershell.namespace: "quickshell:strut-top"
                    anchors { top: true; left: true; right: true }
                    margins.left: manager.barWidth
                    implicitHeight: manager.borderThickness
                    exclusiveZone: manager.borderThickness
                    color: "transparent"
                }
                PanelWindow {
                    screen: screenRoot.modelData
                    WlrLayershell.layer: WlrLayer.Top
                    WlrLayershell.namespace: "quickshell:strut-bottom"
                    anchors { bottom: true; left: true; right: true }
                    margins.left: manager.barWidth
                    implicitHeight: manager.borderThickness
                    exclusiveZone: manager.borderThickness
                    color: "transparent"
                }
                PanelWindow {
                    screen: screenRoot.modelData
                    WlrLayershell.layer: WlrLayer.Top
                    WlrLayershell.namespace: "quickshell:strut-right"
                    anchors { top: true; bottom: true; right: true }
                    implicitWidth: manager.borderThickness
                    exclusiveZone: manager.borderThickness
                    color: "transparent"
                }

                // === The single visible surface ===
                // Fullscreen, ignores exclusion zones (its own struts
                // above included) so it can paint the bar and the
                // border strips as one continuous, seam-proof scene.
                PanelWindow {
                    id: frame
                    screen: screenRoot.modelData
                    WlrLayershell.layer: WlrLayer.Top
                    WlrLayershell.namespace: "quickshell:frame"
                    exclusionMode: ExclusionMode.Ignore
                    anchors { top: true; bottom: true; left: true; right: true }
                    color: "transparent"

                    // CRITICAL: without a mask, this window is a
                    // fullscreen input sink -- it would swallow every
                    // click/scroll over the ENTIRE monitor, not just
                    // the bar, even though only the bar has anything
                    // interactive in it. Restrict hit-testing to just
                    // the bar's rectangle so everything else (border
                    // strips, and the empty space over your other
                    // windows) passes clicks straight through to
                    // whatever's underneath.
                    mask: Region {
                        Region { item: barArea }
                        Region { item: bluetoothPanelContent }
                        Region { item: dimScrim }
                        Region { item: powerMenuContent }
                    }

                    // --- Border strips, drawn edge-to-edge across the
                    // FULL window. The bar (below) is opaque and sits
                    // visually on top of the left end of the top/bottom
                    // strips -- that's deliberate overlap, not a seam,
                    // so there is no gap for it to ever crack open. ---
                    Rectangle {
                        anchors { left: parent.left; right: parent.right; top: parent.top }
                        height: manager.borderThickness
                        color: manager.frameColor
                        antialiasing: false
                    }
                    Rectangle {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: manager.borderThickness
                        color: manager.frameColor
                        antialiasing: false
                        z: 5
                    }
                    Rectangle {
                        anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
                        width: manager.borderThickness
                        color: manager.frameColor
                        antialiasing: false
                        z: 5
                    }

                    // --- Full-screen dim scrim, only "live" while the
                    // power menu is open. Clicking it closes the menu.
                    // visible-gated so it drops out of the mask below
                    // when hidden -- confirm Region actually excludes
                    // invisible items on your Quickshell version; if
                    // not, tell me and I'll switch this to a
                    // width/height-collapse trick instead. ---
                    Rectangle {
                        id: dimScrim
                        anchors.top: parent.top
                        anchors.left: parent.left
                        // width/height collapse to 0 when hidden -- this is the actual
                        // fix. `visible: false` alone does NOT shrink the mask region,
                        // since Region tracks geometry, not paint state.
                        width: PowerMenu.shown ? parent.width : 0
                        height: PowerMenu.shown ? parent.height : 0
                        color: "black"
                        opacity: PowerMenu.shown ? 0.55 : 0
                        visible: PowerMenu.shown
                        antialiasing: false
                        z: 3

                        Behavior on opacity {
                            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: PowerMenu.hide()
                        }   
                    }

                    // --- Left bar, same window/same coordinate space
                    // as the border strips above it in the tree. ---
                    Bar {
                        id: barArea
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        barWidth: manager.barWidth
                    }

                    BluetoothPanelContent {
                        id: bluetoothPanelContent
                    }

                    PowerMenuContent {
                        id: powerMenuContent
                    }

                    // --- Corner accents, straddling each true corner.
                    // Because everything above lives in `frame`, these
                    // coordinates are exact -- no cross-window guessing. ---
                    CornerAccent {
                        corner: "topLeft"
                        thickness: manager.borderThickness
                        color: manager.accentColor
                        anchors.left: parent.left
                        anchors.top: parent.top
                        z: 10
                    }
                    CornerAccent {
                        corner: "bottomLeft"
                        thickness: manager.borderThickness
                        color: manager.accentColor
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        z: 10
                    }
                    CornerAccent {
                        corner: "topRight"
                        thickness: manager.borderThickness
                        color: manager.accentColor
                        anchors.right: parent.right
                        anchors.top: parent.top
                        z: 10
                    }
                    CornerAccent {
                        corner: "bottomRight"
                        thickness: manager.borderThickness
                        color: manager.accentColor
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        z: 10
                    }
                }
            }
        }
    }
}
