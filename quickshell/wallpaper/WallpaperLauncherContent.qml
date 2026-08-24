import QtQuick
import QtQuick.Layouts
import Quickshell
import "../bar" as Bar

Item {
    id: content
    property int topOffset: 4
    property int cols: 4
    property int rows: 3
    property int cellSize: 108
    property int cellSpacing: 14

    readonly property int perPage: cols * rows
    readonly property int pageWidth: cols * (cellSize + cellSpacing) - cellSpacing
    readonly property int pageHeight: rows * (cellSize + cellSpacing) - cellSpacing
    readonly property int pageCount: Math.max(1, Math.ceil(WallpaperBackend.wallpapers.length / perPage))
    readonly property int currentPage: pageWidth > 0 ? Math.round(pager.contentX / pageWidth) : 0

    implicitWidth: WallpaperLauncher.shown ? bezel.width : 0
    implicitHeight: WallpaperLauncher.shown ? bezel.height : 0
    anchors.centerIn: parent
    opacity: WallpaperLauncher.shown ? 1 : 0
    scale: WallpaperLauncher.shown ? 1 : 0.97
    visible: opacity > 0.01
    z: 6

    Behavior on opacity {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }
    Behavior on scale {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    NumberAnimation {
        id: snapAnim
        target: pager
        property: "contentX"
        duration: 260
        easing.type: Easing.OutCubic
    }

    function clampX(x) {
        return Math.max(0, Math.min(pager.contentWidth - pager.width, x));
    }
    function pageBy(delta) {
        snapAnim.stop();
        snapAnim.to = content.clampX(pager.contentX + delta * content.pageWidth);
        snapAnim.restart();
    }
    function snapToNearest() {
        const target = Math.round(pager.contentX / content.pageWidth) * content.pageWidth;
        snapAnim.stop();
        snapAnim.to = content.clampX(target);
        snapAnim.restart();
    }

    Timer {
        id: wheelCooldown
        interval: 350
    }

    // soft backdrop stand-in for a drop shadow -- avoids depending on
    // an unverified shadow component, cheap and reliable
    Rectangle {
        anchors.centerIn: parent
        width: panelBox.width + 24
        height: panelBox.height + 24
        radius: 20
        color: Bar.Colors.shadow
        opacity: 0.55
        antialiasing: true
    }

    Rectangle {
        id: bezel
        anchors.centerIn: parent
        width: panelBox.width + 2
        height: panelBox.height + 2
        radius: 16
        color: Bar.Colors.outlineVariant
        antialiasing: true

        Rectangle {
            id: panelBox
            anchors.centerIn: parent
            width: content.pageWidth + 64
            height: content.pageHeight + 48
            radius: 15
            color: Bar.Colors.surfaceContainerLow
            antialiasing: true
            clip: true

            Text {
                anchors.centerIn: parent
                visible: WallpaperBackend.scanning
                text: "Loading wallpapers..."
                font.family: "Cozette"
                font.pixelSize: 11
                color: Bar.Colors.mutedOnBackground
            }

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: pager.verticalCenter
                anchors.leftMargin: 14
                text: "‹"
                font.pixelSize: 22
                font.weight: Font.Light
                color: leftArrowArea.containsMouse ? Bar.Colors.accent : Bar.Colors.mutedOnBackground
                opacity: content.currentPage > 0 ? 1 : 0.2
                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }
                MouseArea {
                    id: leftArrowArea
                    anchors.fill: parent
                    anchors.margins: -10
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: content.currentPage > 0
                    onClicked: content.pageBy(-1)
                }
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: pager.verticalCenter
                anchors.rightMargin: 14
                text: "›"
                font.pixelSize: 22
                font.weight: Font.Light
                color: rightArrowArea.containsMouse ? Bar.Colors.accent : Bar.Colors.mutedOnBackground
                opacity: content.currentPage < content.pageCount - 1 ? 1 : 0.2
                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }
                MouseArea {
                    id: rightArrowArea
                    anchors.fill: parent
                    anchors.margins: -10
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: content.currentPage < content.pageCount - 1
                    onClicked: content.pageBy(1)
                }
            }

            Flickable {
                id: pager
                anchors.top: parent.top
                anchors.topMargin: 16
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

                                        property int wpIndex: pageItem.pageIndex * content.perPage + index
                                        property var wp: wpIndex < WallpaperBackend.wallpapers.length ? WallpaperBackend.wallpapers[wpIndex] : null
                                        visible: wp !== null
                                        scale: tileArea.containsMouse ? 1.03 : 1.0
                                        Behavior on scale {
                                            NumberAnimation {
                                                duration: 140
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        Rectangle {
                                            id: tileFrame
                                            anchors.fill: parent
                                            radius: 10
                                            color: Bar.Colors.surfaceContainer
                                            antialiasing: true
                                            border.width: tileArea.containsMouse ? 2 : 0
                                            border.color: Bar.Colors.accent
                                            Behavior on border.width {
                                                NumberAnimation {
                                                    duration: 140
                                                }
                                            }

                                            // fixed inset keeps the image's square corners tucked
                                            // safely behind the frame's rounded curve -- no per-image
                                            // clip mask needed
                                            Image {
                                                anchors.fill: parent
                                                anchors.margins: 3
                                                source: tile.wp ? "file://" + tile.wp.path : ""
                                                fillMode: Image.PreserveAspectCrop
                                                smooth: true
                                                asynchronous: true
                                                sourceSize.width: content.cellSize
                                                sourceSize.height: content.cellSize
                                            }
                                        }

                                        Rectangle {
                                            anchors.bottom: parent.bottom
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.margins: 4
                                            height: 22
                                            radius: 6
                                            color: Bar.Colors.shadow
                                            opacity: tileArea.containsMouse ? 0.85 : 0
                                            visible: opacity > 0.01
                                            Behavior on opacity {
                                                NumberAnimation {
                                                    duration: 140
                                                }
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                text: tile.wp ? tile.wp.name : ""
                                                color: Bar.Colors.textOnBackground
                                                font.family: "Cozette"
                                                font.pixelSize: 9
                                                elide: Text.ElideRight
                                                width: parent.width - 10
                                                horizontalAlignment: Text.AlignHCenter
                                            }
                                        }

                                        MouseArea {
                                            id: tileArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                WallpaperBackend.apply(tile.wp.path);
                                                WallpaperLauncher.hide();
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
                onWheel: event => {
                    if (!wheelCooldown.running) {
                        const delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
                        content.pageBy(delta < 0 ? 1 : -1);
                        wheelCooldown.restart();
                    }
                    event.accepted = true;
                }
            }

            Row {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: 14
                spacing: 6
                Repeater {
                    model: content.pageCount
                    delegate: Rectangle {
                        width: index === content.currentPage ? 16 : 5
                        height: 5
                        radius: 2.5
                        antialiasing: true
                        color: index === content.currentPage ? Bar.Colors.accent : Bar.Colors.outlineVariant
                        Behavior on width {
                            NumberAnimation {
                                duration: 160
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
            }
        }
    }
}
