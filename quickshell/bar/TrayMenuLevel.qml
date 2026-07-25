import QtQuick
import QtQuick.Layouts
import Quickshell
import "."

Item {
    id: level
    required property var levelData
    required property int levelIndex

    implicitWidth: 180
    implicitHeight: panelBox.height
    width: implicitWidth
    height: implicitHeight
    x: Math.min(Math.max(levelData.x, 0), parent ? parent.width - width : 0)
    y: Math.min(Math.max(levelData.y, 0), parent ? parent.height - height : 0)
    z: 10 + levelIndex

    QsMenuOpener {
        id: opener
        menu: level.levelData.handle
    }

    Rectangle {
        id: panelBox
        width: level.implicitWidth
        height: menuColumn.implicitHeight + 16
        color: Colors.background
        antialiasing: false
        z: 0

        Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Colors.outlineVariant; z: 1 }
        Rectangle { anchors.left: parent.left; height: parent.height; width: 1; color: Colors.outlineVariant; z: 1 }
        Rectangle { anchors.right: parent.right; height: parent.height; width: 1; color: Colors.outlineVariant; z: 1 }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Colors.outlineVariant; z: 1 }

        Repeater {
            model: [
                { x: -1, y: -1, hFlip: false, vFlip: false },
                { x: panelBox.width - 9, y: -1, hFlip: true, vFlip: false },
                { x: -1, y: panelBox.height - 9, hFlip: false, vFlip: true },
                { x: panelBox.width - 9, y: panelBox.height - 9, hFlip: true, vFlip: true }
            ]
            delegate: Item {
                x: modelData.x; y: modelData.y
                width: 10; height: 10
                z: 2
                Rectangle {
                    width: 3; height: 10; antialiasing: false; color: Colors.outline
                    x: modelData.hFlip ? 7 : 0
                }
                Rectangle {
                    width: 10; height: 3; antialiasing: false; color: Colors.outline
                    y: modelData.vFlip ? 7 : 0
                }
            }
        }

        ColumnLayout {
            id: menuColumn
            anchors.fill: parent
            anchors.margins: 8
            spacing: 2
            z: 3

            Repeater {
                model: opener.children
                delegate: Loader {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: modelData.isSeparator ? 1 : 24
                    sourceComponent: modelData.isSeparator ? sepComp : itemComp

                    Component {
                        id: sepComp
                        Rectangle { anchors.fill: parent; color: Colors.surfaceContainerHigh; antialiasing: false }
                    }

                    Component {
                        id: itemComp
                        Rectangle {
                            id: rowRect
                            anchors.fill: parent
                            color: entryArea.containsMouse ? Colors.surfaceContainer : "transparent"
                            antialiasing: false
                            opacity: modelData.enabled ? 1.0 : 0.4

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.right: arrow.visible ? arrow.left : parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.text
                                color: Colors.onSurface
                                font.family: "Cozette"
                                font.pixelSize: 9
                                elide: Text.ElideRight
                            }

                            Text {
                                id: arrow
                                visible: modelData.hasChildren
                                anchors.right: parent.right
                                anchors.rightMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                text: ">"
                                color: Colors.mutedOnBackground
                                font.family: "Cozette"
                                font.pixelSize: 9
                            }

                            MouseArea {
                                id: entryArea
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: modelData.enabled
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.hasChildren) {
                                        const pos = mapToItem(null, rowRect.width, 0)
                                        TrayMenu.openSubmenu(modelData, pos.x, pos.y, level.levelIndex + 1)
                                    } else {
                                        modelData.triggered()
                                        TrayMenu.hide()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Text {
                visible: opener.children.count === 0
                text: "empty"
                color: Colors.mutedOnBackground
                font.family: "Cozette"
                font.pixelSize: 9
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}