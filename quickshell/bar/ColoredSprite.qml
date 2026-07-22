import QtQuick
import Quickshell.Io

// Idle -> hover sequencing:
//   hovered becomes true  -> plays the accent sheet once, start to finish
//                             ("charging up")
//   charge finishes        -> automatically switches to the hover sheet,
//                             which loops for as long as still hovered
//                             ("exploded" / released state)
//   hovered becomes false  -> resets back to frame 0 of the charge phase,
//                             ready to charge again next hover
//
// Takes plain filesystem paths (same convention as ReactiveImage), not
// file:// URLs -- file:// is only prepended internally for each Image's
// source. Both sheets hot-reload independently when
// generate-theme-assets.sh reruns.
Item {
    id: root
    property string accentSource: ""
    property string hoverSource: ""
    property bool hovered: false

    property int frameW: 24
    property int frameH: 24
    property int chargeFrameCount: 5   // frames in accentSource (charge-up)
    property int hoverFrameCount: 5    // frames in hoverSource (explosion)
    property int fps: 8
    property bool loopHover: true      // false = freeze on last explosion frame

    width: frameW
    height: frameH

    // "charge" or "hover"
    property string phase: "charge"
    property int currentFrame: 0

    onHoveredChanged: {
        // Always restart from the beginning of the charge phase, whether
        // we're entering or leaving hover.
        phase = "charge"
        currentFrame = 0
    }

    Image {
        id: accentSheet
        anchors.fill: parent
        smooth: false
        cache: false
        visible: root.hovered && root.phase === "charge"
        source: root.accentSource === "" ? "" : "file://" + root.accentSource
        sourceClipRect: Qt.rect(root.currentFrame * root.frameW, 0, root.frameW, root.frameH)
    }

    Image {
        id: hoverSheet
        anchors.fill: parent
        smooth: false
        cache: false
        visible: root.hovered && root.phase === "hover"
        source: root.hoverSource === "" ? "" : "file://" + root.hoverSource
        sourceClipRect: Qt.rect(root.currentFrame * root.frameW, 0, root.frameW, root.frameH)
    }

    FileView {
        id: accentWatcher
        path: root.accentSource
        watchChanges: true
        onFileChanged: {
            accentSheet.source = ""
            accentSheet.source = "file://" + root.accentSource
        }
    }

    FileView {
        id: hoverWatcher
        path: root.hoverSource
        watchChanges: true
        onFileChanged: {
            hoverSheet.source = ""
            hoverSheet.source = "file://" + root.hoverSource
        }
    }

    Timer {
        interval: 1000 / root.fps
        running: root.hovered
        repeat: true
        onTriggered: {
            if (root.phase === "charge") {
                root.currentFrame++
                if (root.currentFrame >= root.chargeFrameCount) {
                    root.phase = "hover"
                    root.currentFrame = 0
                }
            } else {
                if (root.currentFrame + 1 < root.hoverFrameCount) {
                    root.currentFrame++
                } else if (root.loopHover) {
                    root.currentFrame = 0
                }
                // else: hold on the last explosion frame
            }
        }
    }
}