import QtQuick
import QtQuick.Layouts
import Quickshell
import "../bar" as Bar

Item {
    id: content
    property int topOffset: 4
    property int cols: 4
    property int rows: 3
    property int cellSize: 96
    property int cellSpacing: 8

    readonly property int perPage: cols * rows
    readonly property int pageWidth: cols * (cellSize + cellSpacing) - cellSpacing
    readonly property int pageHeight: rows * (cellSize + cellSpacing) - cellSpacing
    readonly property int pageCount: Math.max(1, Math.ceil(WallpaperBackend.wallpapers.length / perPage))
    readonly property int currentPage: pageWidth > 0 ? Math.round(pager.contentX / pageWidth) : 0

    implicitWidth: WallpaperLauncher.shown ? bezel.width : 0
    implicitHeight: WallpaperLauncher.shown ? bezel.height : 0
    anchors.centerIn: parent
    opacity: WallpaperLauncher.shown ? 1 : 0
    scale: WallpaperLauncher.shown ? 1 : 0.96
    visible: opacity > 0.01
    z: 6

    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    NumberAnimation {
        id: snapAnim
        target: pager
        property: "contentX"
        duration: 220
        easing.type: Easing.OutCubic
    }

    function clampX(x) {
        return Math.max(0, Math.min(pager.contentWidth - pager.width, x))
    }

    function pageBy(delta) {
        snapAnim.stop()
        snapAnim.to = content.clampX(pager.contentX + delta * content.pageWidth)
        snapAnim.restart()
    }

    function snapToNearest() {
        const target = Math.round(pager.contentX / content.pageWidth) * content.pageWidth
        snapAnim.stop()
        snapAnim.to = content.clampX(target)
        snapAnim.restart()
    }

    Timer {
        id: wheelCooldown
        interval: 350
    }

    Rectangle {
        id: bezel
        anchors.centerIn: parent
        width: panelBox.width + 12
        height: panelBox.height + 12
        color: Bar.Colors.shadow
        antialiasing: false

        Repeater {
            model: [
                { x: 3, y: 3 }, { x: bezel.width - 5, y: 3 },
                { x: 3, y: bezel.height - 5 }, { x: bezel.width - 5, y: bezel.height - 5 }
            ]
            delegate: Rectangle {
                x: modelData.x; y: modelData.y
                width: 2; height: 2
                color: Bar.Colors.outline
                antialiasing: false
            }
        }

        Rectangle {
            id: panelBox
            anchors.centerIn: parent
            width: content.pageWidth + 56
            height: content.pageHeight + 32
            color: Bar.Colors.background
            antialiasing: false
            clip: true

            Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Bar.Colors.outlineVariant }
            Rectangle { anchors.left: parent.left; height: parent.height; width: 1; color: Bar.Colors.outlineVariant }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Bar.Colors.outlineVariant }
            Rectangle { anchors.right: parent.right; height: parent.height; width: 1; color: Bar.Colors.outlineVariant }

            Text {
                anchors.centerIn: parent
                visible: WallpaperBackend.scanning
                text: "Loading wallpapers..."
                font.family: "Cozette"
                font.pixelSize: 10
                color: Bar.Colors.textOnBackground
            }

            Column {
                anchors.fill: parent
                spacing: 2
                Repeater {
                    model: Math.ceil(panelBox.height / 3)
                    delegate: Rectangle {
                        width: panelBox.width
                        height: 1
                        color: Bar.Colors.textOnBackground
                        opacity: 0.02
                    }
                }
            }

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: pager.verticalCenter
                anchors.leftMargin: 10
                text: "<"
                font.family: "Cozette"
                font.pixelSize: 14
                color: leftArrowArea.containsMouse ? Bar.Colors.accent : Bar.Colors.outline
                opacity: content.currentPage > 0 ? 1 : 0.25
                MouseArea {
                    id: leftArrowArea
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: content.currentPage > 0
                    onClicked: content.pageBy(-1)
                }
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: pager.verticalCenter
                anchors.rightMargin: 10
                text: ">"
                font.family: "Cozette"
                font.pixelSize: 14
                color: rightArrowArea.containsMouse ? Bar.Colors.accent : Bar.Colors.outline
                opacity: content.currentPage < content.pageCount - 1 ? 1 : 0.25
                MouseArea {
                    id: rightArrowArea
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: content.currentPage < content.pageCount - 1
                    onClicked: content.pageBy(1)
                }
            }

            Flickable {
                id: pager
                anchors.top: parent.top
                anchors.topMargin: 8
                anchors.horizontalCenter: parent.horizontalCenter
                width: content.pageWidth
                height: content.pageHeight
                contentWidth: content.pageWidth * content.pageCount
                contentHeight: content.pageHeight
                flickableDirection: Flickable.HorizontalFlick
                boundsBehavior: Flickable.StopAtBounds
                flickDeceleration: 4000
                maximumFlickVelocity: 2500
                clip: true

                onMovementEnded: content.snapToNearest()
                onFlickEnded: content.snapToNearest()

                Row {
                    Repeater {
                        model: content.pageCount
                        delegate: Item {
                            id: pageItem
                            width: content.pageWidth
                            height: content.pageHeight
                            property int pageIndex: index

                            Grid {
                                anchors.fill: parent
                                columns: content.cols
                                rowSpacing: content.cellSpacing
                                columnSpacing: content.cellSpacing

                                Repeater {
                                    model: content.perPage
                                    delegate: Item {
                                        id: tile
                                        width: content.cellSize
                                        height: content.cellSize
                                        clip: false

                                        property int wpIndex: pageItem.pageIndex * content.perPage + index
                                        property var wp: wpIndex < WallpaperBackend.wallpapers.length
                                            ? WallpaperBackend.wallpapers[wpIndex] : null
                                        visible: wp !== null

                                        Rectangle {
                                            anchors.fill: parent
                                            color: tileArea.containsMouse ? Bar.Colors.surfaceContainerHigh : Bar.Colors.surfaceContainer
                                            antialiasing: false
                                        }

                                        Image {
                                            anchors.fill: parent
                                            anchors.margins: 4
                                            source: tile.wp ? "file://" + tile.wp.path : ""
                                            fillMode: Image.PreserveAspectCrop
                                            smooth: false
                                            asynchronous: true
                                            clip: true
                                            sourceSize.width: content.cellSize - 8
                                            sourceSize.height: content.cellSize - 8
                                        }

                                        Bar.CornerAccent {
                                            corner: "topLeft"
                                            thickness: 2
                                            sizeScale: 24
                                            color: tileArea.containsMouse ? Bar.Colors.accent : Bar.Colors.outline
                                            anchors.top: parent.top
                                            anchors.left: parent.left
                                        }
                                        Bar.CornerAccent {
                                            corner: "topRight"
                                            thickness: 2
                                            sizeScale: 24
                                            color: tileArea.containsMouse ? Bar.Colors.accent : Bar.Colors.outline
                                            anchors.top: parent.top
                                            anchors.right: parent.right
                                        }
                                        Bar.CornerAccent {
                                            corner: "bottomLeft"
                                            thickness: 2
                                            sizeScale: 24
                                            color: tileArea.containsMouse ? Bar.Colors.accent : Bar.Colors.outline
                                            anchors.bottom: parent.bottom
                                            anchors.left: parent.left
                                        }
                                        Bar.CornerAccent {
                                            corner: "bottomRight"
                                            thickness: 2
                                            sizeScale: 24
                                            color: tileArea.containsMouse ? Bar.Colors.accent : Bar.Colors.outline
                                            anchors.bottom: parent.bottom
                                            anchors.right: parent.right
                                        }

                                        Rectangle {
                                            anchors.bottom: parent.bottom
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            height: 16
                                            color: Bar.Colors.shadow
                                            opacity: 0.8
                                            visible: tileArea.containsMouse

                                            Text {
                                                anchors.centerIn: parent
                                                text: tile.wp ? tile.wp.name : ""
                                                color: Bar.Colors.textOnBackground
                                                font.family: "Cozette"
                                                font.pixelSize: 8
                                                elide: Text.ElideRight
                                                width: parent.width - 4
                                                horizontalAlignment: Text.AlignHCenter
                                            }
                                        }

                                        MouseArea {
                                            id: tileArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                WallpaperBackend.apply(tile.wp.path)
                                                WallpaperLauncher.hide()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: pager
                z: 5
                acceptedButtons: Qt.NoButton
                hoverEnabled: false
                onWheel: (event) => {
                    if (!wheelCooldown.running) {
                        const delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x
                        content.pageBy(delta < 0 ? 1 : -1)
                        wheelCooldown.restart()
                    }
                    event.accepted = true
                }
            }

            Row {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: 8
                spacing: 5
                Repeater {
                    model: content.pageCount
                    delegate: Rectangle {
                        width: 4; height: 4
                        antialiasing: false
                        color: index === content.currentPage ? Bar.Colors.accent : Bar.Colors.outlineVariant
                    }
                }
            }
        }
    }
}