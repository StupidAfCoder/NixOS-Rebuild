pragma Singleton
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property bool shown: false
    function toggle() { shown = !shown }
    function hide() { shown = false }

    PanelWindow {
        id: overlay
        visible: root.shown
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:powermenu"
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        mask: Region { item: menuBox }

        // click outside the box closes it
        MouseArea {
            anchors.fill: parent
            onClicked: root.hide()
        }

        Rectangle {
            id: menuBox
            anchors.centerIn: parent
            width: 300
            height: 100
            radius: 6
            color: "#1a1b26"
            border.color: "#414868"
            border.width: 1
            antialiasing: false

            RowLayout {
                anchors.centerIn: parent
                spacing: 16

                PowerMenuButton {
                    iconName: "lock.svg"; label: "Lock"
                    onTriggered: { root.hide(); Quickshell.execDetached(["hyprlock"]) }
                }
                PowerMenuButton {
                    iconName: "logout.svg"; label: "Logout"
                    onTriggered: { root.hide(); Hyprland.dispatch("hl.dsp.exit()") }
                }
                PowerMenuButton {
                    iconName: "moon.svg"; label: "Sleep"
                    onTriggered: { root.hide(); Quickshell.execDetached(["systemctl", "suspend"]) }
                }
                PowerMenuButton {
                    iconName: "reload.svg"; label: "Reboot"
                    onTriggered: { root.hide(); Quickshell.execDetached(["systemctl", "reboot"]) }
                }
                PowerMenuButton {
                    iconName: "power-off.svg"; label: "Shutdown"
                    onTriggered: { root.hide(); Quickshell.execDetached(["systemctl", "poweroff"]) }
                }
            }
        }
    }
}