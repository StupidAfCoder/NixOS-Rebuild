import Quickshell
import QtQuick
import Quickshell.Services.Notifications as Notifs
import Quickshell.Wayland
import "." as Local

Scope {
    id: manager

    Notifs.NotificationServer {
        id: server
        keepOnReload: true
        onNotification: (notification) => {
            notification.tracked = true
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: toastWindow
                required property var modelData
                screen: toastWindow.modelData

                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "quickshell:notifications"

                anchors { top: true; right: true }
                implicitWidth: 400
                implicitHeight: 700
                color: "transparent"

                margins { top: 16; right: 16 }

                // Mask sized to actual content, not the full window,
                // so empty space below the stack passes clicks through
                mask: Region { item: listView }

                ListView {
                    id: listView
                    anchors.top: parent.top
                    width: parent.width
                    height: Math.min(contentHeight, parent.height)
                    interactive: false
                    spacing: 10
                    model: server.trackedNotifications

                    add: Transition {
                        NumberAnimation { property: "revealProgress"; from: 0; to: 1; duration: 560; easing.type: Easing.OutQuint }
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 240 }
                    }
                    remove: Transition {
                        NumberAnimation { property: "revealProgress"; to: 0; duration: 420; easing.type: Easing.InQuint }
                        NumberAnimation { property: "opacity"; to: 0; duration: 240 }
                    }
                    displaced: Transition {
                        NumberAnimation { property: "y"; duration: 180; easing.type: Easing.OutQuad }
                    }

                    delegate: Local.NotificationCard {
                        width: listView.width
                    }
                }
            }
        }
    }
}