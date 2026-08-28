import QtQuick
import "../bar"

Item {
    id: root
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter

    property int topOffset: 0
    readonly property int hoverStripWidth: 220
    readonly property int hoverStripHeight: topOffset
    readonly property int bezelWidth: 320
    readonly property int bezelHeight: 190

    property alias hoverStripItem: hoverStrip
    property alias panelBezelItem: maskArea

    Item {
        id: hoverStrip
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.hoverStripWidth
        height: root.hoverStripHeight

        HoverHandler {
            onHoveredChanged: hovered ? SysStatsPanel.show() : SysStatsPanel.scheduleHide()
        }
    }

    // ---- mask-only hitbox ----
    // Deliberately NOT animated. This is the item registered in the window's
    // `mask`, so it must snap discretely between 0x0 and full size on the
    // same frame `shown` changes. Never put a Behavior on this item.
    Item {
        id: maskArea
        anchors.top: hoverStrip.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: SysStatsPanel.shown ? root.bezelWidth : 0
        height: SysStatsPanel.shown ? root.bezelHeight : 0
    }

    Rectangle {
        id: bezel
        anchors.top: hoverStrip.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.bezelWidth
        height: root.bezelHeight
        color: Colors.shadow
        antialiasing: false

        y: hoverStrip.height + (SysStatsPanel.shown ? 0 : -220)
        opacity: SysStatsPanel.shown ? 1 : 0
        visible: opacity > 0.01

        Behavior on y {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        HoverHandler {
            onHoveredChanged: {
                if (hovered)
                    SysStatsPanel.cancelHide();
                else
                    SysStatsPanel.scheduleHide();
            }
        }

        Repeater {
            model: [
                {
                    x: 3,
                    y: 3
                },
                {
                    x: bezel.width - 5,
                    y: 3
                },
                {
                    x: 3,
                    y: bezel.height - 5
                },
                {
                    x: bezel.width - 5,
                    y: bezel.height - 5
                }
            ]
            delegate: Rectangle {
                x: modelData.x
                y: modelData.y
                width: 2
                height: 2
                color: Colors.outline
                antialiasing: false
            }
        }

        Rectangle {
            id: panelBox
            anchors.centerIn: parent
            width: bezel.width - 12
            height: bezel.height - 12
            color: Colors.background
            border.color: Colors.outlineVariant
            border.width: 1
            antialiasing: false
            clip: true

            // ---- scanline overlay: thin translucent lines every 3px ----
            Column {
                anchors.fill: parent
                spacing: 2
                z: 10
                Repeater {
                    model: Math.ceil(panelBox.height / 3)
                    delegate: Rectangle {
                        width: panelBox.width
                        height: 1
                        color: Colors.shadow
                        opacity: 0.06
                        antialiasing: false
                    }
                }
            }

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 16

                // ---- stat rows: segmented pixel meters ----
                Repeater {
                    model: [
                        {
                            label: "CPU",
                            pct: SysStatsBackend.cpuPct,
                            extra: SysStatsBackend.cpuTemp >= 0 ? SysStatsBackend.cpuTemp + "°C" : ""
                        },
                        {
                            label: "RAM",
                            pct: SysStatsBackend.ramPct,
                            extra: SysStatsBackend.ramUsedGb.toFixed(1) + "/" + SysStatsBackend.ramTotalGb.toFixed(1) + "GB"
                        },
                        {
                            label: "GPU",
                            pct: SysStatsBackend.gpuPct >= 0 ? SysStatsBackend.gpuPct : 0,
                            extra: SysStatsBackend.gpuTemp >= 0 ? SysStatsBackend.gpuTemp + "°C" : "N/A"
                        }
                    ]
                    delegate: Column {
                        width: panelBox.width - 24
                        spacing: 4

                        Row {
                            width: parent.width
                            Text {
                                text: modelData.label
                                color: Colors.textOnBackground
                                font.family: "Cozette"
                                font.pixelSize: 8
                            }
                            Item {
                                width: parent.width - 130
                                height: 1
                            }
                            Text {
                                text: (modelData.pct >= 0 ? modelData.pct + "%" : "N/A") + "  " + modelData.extra
                                color: Colors.mutedOnBackground
                                font.family: "Cozette"
                                font.pixelSize: 7
                            }
                        }

                        // segmented VU-meter bar
                        Row {
                            id: meterRow
                            width: parent.width
                            height: 12
                            spacing: 2

                            readonly property int segmentCount: 28
                            readonly property int litSegments: Math.round(segmentCount * Math.max(0, Math.min(100, modelData.pct)) / 100)
                            readonly property real segW: (width - spacing * (segmentCount - 1)) / segmentCount

                            Repeater {
                                model: meterRow.segmentCount
                                delegate: Rectangle {
                                    width: meterRow.segW
                                    height: meterRow.height
                                    antialiasing: false
                                    color: {
                                        if (index >= meterRow.litSegments)
                                            return Colors.surfaceContainer;
                                        const frac = index / meterRow.segmentCount;
                                        if (frac > 0.85)
                                            return Colors.error;
                                        if (frac > 0.6)
                                            return Colors.warning;
                                        return Colors.accent;
                                    }
                                    border.width: 1
                                    border.color: Colors.outlineVariant
                                    opacity: index < meterRow.litSegments ? 1 : 0.5

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }
                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 150
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
