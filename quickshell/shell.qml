import Quickshell
import QtQuick
import "notifications"
import "bar"

ShellRoot {
    id: root

    // Instantiate our custom notification server framework
    NotificationManager {
        id: notificationManager
    }

    // A tiny visual test anchor to ensure Quickshell is running
    Variants {
        model: Quickshell.screens
        delegate: Component {
            PanelWindow {
                required property var modelData
                screen: modelData
                
                anchors {
                    top: true
                    left: true
                    right: true
                }
                implicitHeight: 2 // Tiny indicator bar at the very top of your screens
                
                Rectangle {
                    anchors.fill: parent
                    color: "#565f89" // Subtle Tokyonight blue accent
                }
            }
        }
    }

    BarManager {}
}