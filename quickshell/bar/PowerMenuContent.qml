import QtQuick
import QtQuick.Layouts
import "."

Item {
    id: content
    implicitWidth: 200
    implicitHeight: 340
    width: implicitWidth
    height: implicitHeight
    anchors.verticalCenter: parent.verticalCenter
    visible: true   // stays visible always -- fully off-screen when hidden, so nothing draws or catches clicks anyway

    // resting position: tucked 2px into the right border. hidden
    // position: slid right until the box is entirely off-screen.
    x: PowerMenu.shown ? (parent.width - width + 2) : parent.width

    Behavior on x {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    Rectangle {
        id: panelBox
        anchors.fill: parent
        color: "#1a1b26"
        antialiasing: false

        // border on three sides only -- the right edge blends into
        // the screen border strip instead of drawing its own seam
        Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: "#414868" }
        Rectangle { anchors.left: parent.left; height: parent.height; width: 1; color: "#414868" }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#414868" }

        MouseArea { anchors.fill: parent } // eat clicks so they don't fall through to the dim scrim

        // top-left / bottom-left corner brackets only -- the right
        // edge has nothing to bracket against, same logic as the
        // bluetooth panel's bottom edge
        Repeater {
            model: [
                { x: -1, y: -1, vFlip: false },
                { x: -1, y: panelBox.height - 9, vFlip: true }
            ]
            delegate: Item {
                x: modelData.x; y: modelData.y
                width: 10; height: 10
                Rectangle {
                    width: 3; height: 10; antialiasing: false; color: "#565f89"
                }
                Rectangle {
                    width: 10; height: 3; antialiasing: false; color: "#565f89"
                    y: modelData.vFlip ? 7 : 0
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Power"
                    color: "#c0caf5"
                    font.family: "Cozette"
                    font.pixelSize: 11
                    font.bold: true
                    Layout.fillWidth: true
                }
                Rectangle {
                    width: 16; height: 16
                    antialiasing: false
                    color: closeArea.containsMouse ? "#f7768e" : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "x"
                        color: closeArea.containsMouse ? "#1a1b26" : "#e0af68"
                        font.family: "Cozette"
                        font.pixelSize: 11
                        font.bold: closeArea.containsMouse
                    }
                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: PowerMenu.hide()
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#414868"; antialiasing: false }

            // --- Placeholder for the Aseprite animation. Fixed frame,
            // dashed border so it's obviously a stand-in. Once you've
            // got the sprite sheet, this becomes an AnimatedSprite (or
            // a Timer-driven frame-swap over an Image) sized to match. ---
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                color: "#16161e"
                border.color: "#414868"
                border.width: 1
                antialiasing: false

                Text {
                    anchors.centerIn: parent
                    text: "[ animation\ngoes here ]"
                    horizontalAlignment: Text.AlignHCenter
                    color: "#565f89"
                    font.family: "Cozette"
                    font.pixelSize: 9
                }
            }

            Item { Layout.fillHeight: true } // pushes buttons to the bottom

            PowerMenuButton {
                label: "Lock"
                iconName: "lock.svg"
                Layout.fillWidth: true
                onClicked: {
                    PowerMenu.hide()
                    // TODO: hook up your actual lock command, e.g.
                    // Quickshell.execDetached(["hyprlock"])
                }
            }
            PowerMenuButton {
                label: "Logout"
                iconName: "logout.svg"
                Layout.fillWidth: true
                onClicked: {
                    PowerMenu.hide()
                    // TODO: e.g. Quickshell.execDetached(["hyprctl", "dispatch", "exit"])
                }
            }
            PowerMenuButton {
                label: "Sleep"
                iconName: "moon.svg"
                Layout.fillWidth: true
                onClicked: {
                    PowerMenu.hide()
                    // TODO: e.g. Quickshell.execDetached(["systemctl", "suspend"])
                }
            }
            PowerMenuButton {
                label: "Reboot"
                iconName: "reload.svg"
                Layout.fillWidth: true
                onClicked: {
                    PowerMenu.hide()
                    // TODO: e.g. Quickshell.execDetached(["systemctl", "reboot"])
                }
            }
            PowerMenuButton {
                label: "Shutdown"
                iconName: "power.svg"
                accent: "#f7768e"
                Layout.fillWidth: true
                onClicked: {
                    PowerMenu.hide()
                    // TODO: e.g. Quickshell.execDetached(["systemctl", "poweroff"])
                }
            }
        }
    }
    z: 6
}