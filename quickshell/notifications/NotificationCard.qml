import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications as Notifs
import Qt5Compat.GraphicalEffects
import QtQuick.Shapes

Item {
    id: root
    required property var modelData
    readonly property var notif: modelData

    readonly property bool isCritical: root.notif && root.notif.urgency === Notifs.NotificationUrgency.Critical
    readonly property color urgencyColor: isCritical
        ? "#f7768e"
        : (root.notif && root.notif.urgency === Notifs.NotificationUrgency.Low ? "#565f89" : "#7aa2f7")

    property bool expanded: false
    readonly property int extraLines: Math.max(0, bodyMeasure.lineCount - 1)
    property real revealProgress: 1

    width: 380
    height: card.height

    Behavior on x {
        enabled: !dragArea.drag.active
        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
    }

    Text {
        id: bodyMeasure
        visible: false
        width: 380 - 42 - 10
        font.family: "Cozette"
        font.pixelSize: 13
        wrapMode: Text.Wrap
        text: (root.notif && root.notif.body) || ""
    }

    MouseArea {
        id: dragArea
        anchors.fill: revealClip
        drag.target: root
        drag.axis: Drag.XAxis
        property real pressX: 0

        onPressed: (mouse) => pressX = mouse.x
        onReleased: (mouse) => {
            const moved = Math.abs(root.x)
            if (moved > root.width * 0.35) {
                if (root.notif) root.notif.dismiss()
            } else if (moved < 4) {
                if (bodyText.truncated || root.expanded) {
                    root.expanded = !root.expanded
                }
            } else {
                root.x = 0
            }
        }
    }

    Item {
        id: revealClip
        width: root.width * root.revealProgress
        height: card.height
        x: (root.width - width) / 2
        clip: true

            // Outer pixel frame — thick black border, no radius, no antialiasing
        Shape {
            id: card
            width: parent.width
            height: inner.height + 4
            antialiasing: false
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: "#000000"
                strokeColor: "transparent"
                PathSvg {
                    path: "M8,0 L" + card.width + ",0 L" + card.width + "," + card.height +
                        " L8," + card.height + " L8," + (card.height - 4) +
                        " L4," + (card.height - 4) + " L4," + (card.height - 8) +
                        " L0," + (card.height - 8) + " L0,8 L4,8 L4,4 L8,4 Z"
                }
            }

            Shape {
                id: inner
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 2
                height: content.implicitHeight + 16
                antialiasing: false
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    fillColor: "#1a1b26"
                    strokeColor: "transparent"
                    PathSvg {
                        path: "M8,0 L" + inner.width + ",0 L" + inner.width + "," + inner.height +
                            " L8," + inner.height + " L8," + (inner.height - 4) +
                            " L4," + (inner.height - 4) + " L4," + (inner.height - 8) +
                            " L0," + (inner.height - 8) + " L0,8 L4,8 L4,4 L8,4 Z"
                    }
                }

                // Urgency panel — full-height colored block on the left, own icon,
                // pixelated notches on its inner-facing corners
                Shape {
                    id: urgencyPanel
                    anchors.left: parent.left
                    anchors.top: parent.top
                    width: 32
                    height: inner.height
                    antialiasing: false
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        fillColor: root.urgencyColor
                        strokeColor: "transparent"
                        PathSvg {
                            path: "M8,0 L32,0 L32," + urgencyPanel.height +
                                " L8," + urgencyPanel.height + " L8," + (urgencyPanel.height - 4) +
                                " L4," + (urgencyPanel.height - 4) + " L4," + (urgencyPanel.height - 8) +
                                " L0," + (urgencyPanel.height - 8) + " L0,8 L4,8 L4,4 L8,4 Z"
                        }
                    }

                    Image {
                        id: urgencyIcon
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        source: "file:///home/swami/.local/share/pixelarticons/svg/info-box-sharp.svg"
                        sourceSize: Qt.size(18, 18)
                        smooth: false
                        visible: false
                    }

                    ColorOverlay {
                        anchors.fill: urgencyIcon
                        source: urgencyIcon
                        color: "#1a1b26"
                    }
                }

                Rectangle {
                    id: endAccent
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 4
                    color: root.urgencyColor
                    antialiasing: false
                }

                ColumnLayout {
                    id: content
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: 6
                    anchors.rightMargin: 14
                    anchors.leftMargin: 42
                    spacing: 1

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: (root.notif && root.notif.appName) ? root.notif.appName.toUpperCase() : "SYSTEM"
                            color: "#bb9af7"
                            font.family: "SilkScreen"
                            font.pixelSize: 10
                            font.letterSpacing: 1
                            renderType: Text.NativeRendering
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Item {
                            id: closeBtnWrapper
                            width: 20
                            height: 20

                            Rectangle {
                                id: closeBg
                                anchors.fill: parent
                                color: closeArea.containsMouse ? "#414868" : "transparent"
                                antialiasing: false

                                Repeater {
                                    model: [
                                        {x: 0, y: 0}, {x: parent.width - 2, y: 0},
                                        {x: 0, y: parent.height - 2}, {x: parent.width - 2, y: parent.height - 2}
                                    ]
                                    delegate: Rectangle {
                                        x: modelData.x
                                        y: modelData.y
                                        width: 2
                                        height: 2
                                        color: "#1a1b26"
                                        antialiasing: false
                                        visible: closeArea.containsMouse
                                    }
                                }
                            }

                            Image {
                                id: closeIcon
                                anchors.fill: parent
                                anchors.margins: 3
                                source: "file:///home/swami/.local/share/pixelarticons/svg/close.svg"
                                sourceSize: Qt.size(14, 14)
                                smooth: false
                                visible: false
                            }

                            ColorOverlay {
                                anchors.fill: closeIcon
                                source: closeIcon
                                color: closeArea.containsMouse ? "#ff5555" : "#f7768e"
                            }

                            MouseArea {
                                id: closeArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: if (root.notif) root.notif.dismiss()
                            }
                        }
                    }

                    Text {
                        text: (root.notif && root.notif.summary) || ""
                        color: "#acb0d0"
                        font.family: "Pixel Operator"
                        font.pixelSize: 20
                        font.bold: true
                        renderType: Text.NativeRendering
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        id: bodyText
                        text: (root.notif && root.notif.body) || ""
                        color: "#7982a9"
                        font.family: "Cozette"
                        font.pixelSize: 13
                        renderType: Text.NativeRendering
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                        maximumLineCount: root.expanded ? 0 : 1
                        elide: root.expanded ? Text.ElideNone : Text.ElideRight
                    }

                    Item {
                        id: chevronWrapper
                        visible: bodyText.truncated || root.expanded
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 2
                        width: 16
                        height: 16

                        Item {
                            id: chevronVisual
                            width: 16
                            height: 16

                            Image {
                                id: chevronIcon
                                anchors.fill: parent
                                source: root.expanded
                                    ? "file:///home/swami/.local/share/pixelarticons/svg/chevron-up.svg"
                                    : "file:///home/swami/.local/share/pixelarticons/svg/chevron-down.svg"
                                sourceSize: Qt.size(16, 16)
                                smooth: false
                                visible: false
                            }

                            ColorOverlay {
                                anchors.fill: chevronIcon
                                source: chevronIcon
                                color: "#7aa2f7"
                            }
                        }

                        SequentialAnimation {
                            running: chevronWrapper.visible
                            loops: Animation.Infinite

                            NumberAnimation {
                                target: chevronVisual
                                property: "y"
                                from: 0
                                to: root.expanded ? -3 : 3
                                duration: 500
                                easing.type: Easing.OutQuad
                            }
                            NumberAnimation {
                                target: chevronVisual
                                property: "y"
                                to: 0
                                duration: 500
                                easing.type: Easing.InQuad
                            }
                            PauseAnimation { duration: 400 }
                        }
                    }
                }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 4
            color: root.urgencyColor
            antialiasing: false
            opacity: 1 - root.revealProgress
        }
        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 4
            color: root.urgencyColor
            antialiasing: false
            opacity: 1 - root.revealProgress
        }
    }

    Timer {
        id: dismissTimer
        interval: (root.notif && root.notif.expireTimeout > 0) ? root.notif.expireTimeout : 8000 + Math.min(extraLines, 10) * 2000
        running: !root.isCritical
        onTriggered: if (root.notif) root.notif.dismiss()
    }
}