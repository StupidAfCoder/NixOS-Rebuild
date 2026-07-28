import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Adjust this import path to match wherever your Colors.qml
// singleton actually lives relative to this folder.
import "../theme"

PanelWindow {
    id: panel
    visible: AppLauncher.isOpen
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    property string pos: AppLauncher.position
    readonly property bool isRight: pos === "right"
    readonly property bool isBottom: pos === "bottom"

    implicitWidth: isRight ? 360 : screen.width
    implicitHeight: isRight ? screen.height : 320

    anchors {
        top: !isBottom
        bottom: isBottom || isRight
        left: !isRight
        right: isRight
    }

    readonly property int hiddenOffsetX: isRight ? implicitWidth : 0
    readonly property int hiddenOffsetY: isRight ? 0 : (isBottom ? implicitHeight : -implicitHeight)

    FocusScope {
        id: scope
        anchors.fill: parent
        focus: AppLauncher.isOpen

        Item {
            id: slider
            width: panel.implicitWidth
            height: panel.implicitHeight
            x: AppLauncher.isOpen ? 0 : panel.hiddenOffsetX
            y: AppLauncher.isOpen ? 0 : panel.hiddenOffsetY

            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
            Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }

            // ---- bezel: same pattern as your other panels ----
            Rectangle {
                id: shadowRect
                anchors.fill: parent
                anchors.margins: -4
                color: Colors.shadow
            }

            Repeater {
                model: 4
                Rectangle {
                    width: 4; height: 4
                    color: Colors.outline
                    x: (index % 2 === 0) ? shadowRect.x : shadowRect.x + shadowRect.width - width
                    y: (index < 2) ? shadowRect.y : shadowRect.y + shadowRect.height - height
                }
            }

            Rectangle {
                id: panelBox
                anchors.fill: parent
                color: Colors.background
                border.width: 2
                border.color: Colors.outline
            }

            Repeater {
                model: 4
                Item {
                    readonly property bool leftSide: index % 2 === 0
                    readonly property bool topSide: index < 2
                    x: leftSide ? 6 : panelBox.width - 16
                    y: topSide ? 6 : panelBox.height - 16
                    width: 10; height: 10

                    Rectangle {
                        width: 10; height: 3
                        color: Colors.accent
                        x: 0
                        y: parent.topSide ? 0 : parent.height - 3
                    }
                    Rectangle {
                        width: 3; height: 10
                        color: Colors.accent
                        x: parent.leftSide ? 0 : parent.width - 3
                        y: 0
                    }
                }
            }

            // ---- content ----
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        width: 10; height: 10
                        color: Colors.accent
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        font.family: "Pixel Operator"
                        font.pixelSize: 16
                        color: Colors.textOnBackground
                        text: AppLauncher.query
                        cursorVisible: true
                        focus: true

                        onTextChanged: AppLauncher.query = text
                        Keys.onDownPressed: grid.moveSelection(1)
                        Keys.onUpPressed: grid.moveSelection(-1)
                        Keys.onRightPressed: if (!panel.isRight) grid.moveSelection(1)
                        Keys.onLeftPressed: if (!panel.isRight) grid.moveSelection(-1)
                        Keys.onReturnPressed: grid.launchSelected()
                        Keys.onEnterPressed: grid.launchSelected()
                        Keys.onEscapePressed: AppLauncher.hide()
                    }

                    Text {
                        text: results.length + " results"
                        color: Colors.outline
                        font.family: "Pixel Operator"
                        font.pixelSize: 8
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 2
                    color: Colors.outline
                }

                readonly property var results: AppLauncherBackend.filtered(AppLauncher.query)

                GridView {
                    id: grid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    cellWidth: panel.isRight ? panel.implicitWidth - 40 : 100
                    cellHeight: panel.isRight ? 56 : 84
                    flow: panel.isRight ? GridView.TopToBottom : GridView.LeftToRight
                    model: parent.results

                    function moveSelection(delta) {
                        var count = grid.count
                        if (count === 0) return
                        var next = (AppLauncher.selectedIndex + delta + count) % count
                        AppLauncher.selectedIndex = next
                        grid.positionViewAtIndex(next, GridView.Contain)
                    }

                    function launchSelected() {
                        var item = grid.model[AppLauncher.selectedIndex]
                        AppLauncherBackend.launch(item)
                    }

                    delegate: Item {
                        id: delegateRoot
                        width: grid.cellWidth
                        height: grid.cellHeight
                        readonly property bool selected: index === AppLauncher.selectedIndex

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            color: delegateRoot.selected ? Colors.surface : "transparent"
                            border.width: delegateRoot.selected ? 2 : 0
                            border.color: Colors.accent
                        }

                        RowLayout {
                            visible: panel.isRight
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10
                            PixelIcon {
                                iconSource: modelData.icon
                                displaySize: 32
                                pixelSize: 8
                            }
                            Text {
                                Layout.fillWidth: true
                                text: modelData.name
                                elide: Text.ElideRight
                                color: Colors.textOnBackground
                                font.family: "Pixel Operator"
                                font.pixelSize: 16
                            }
                        }

                        ColumnLayout {
                            visible: !panel.isRight
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6
                            PixelIcon {
                                Layout.alignment: Qt.AlignHCenter
                                iconSource: modelData.icon
                                displaySize: 40
                                pixelSize: 10
                            }
                            Text {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData.name
                                elide: Text.ElideRight
                                color: Colors.textOnBackground
                                font.family: "Pixel Operator"
                                font.pixelSize: 8
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: AppLauncher.selectedIndex = index
                            onClicked: AppLauncherBackend.launch(modelData)
                        }
                    }
                }
            }
        }
    }
}