import Quickshell
import QtQuick
import Quickshell.Services.Notifications as Notifs
import Quickshell.Wayland
import "." as Local
import "../common"

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
                implicitWidth: Math.min(400, screen.width - Settings.desktopInsets.left - Settings.desktopInsets.right - 32)
                implicitHeight: Math.max(1, screen.height - Settings.desktopInsets.top - Settings.desktopInsets.bottom - 32)
                color: "transparent"

                margins { top: Settings.desktopInsets.top + 10; right: Settings.desktopInsets.right + 10 }

                // Mask sized to actual content, not the full window,
                // so empty space below the stack passes clicks through
                mask: Region { item: listView }

                ListView {
                    id: listView
                    anchors.top: parent.top
                    width: parent.width
                    height: Math.min(contentHeight, parent.height)
                    interactive: contentHeight > height
                    clip: true
                    spacing: 10
                    model: server.trackedNotifications

                    add: Transition {
                        NumberAnimation { property: "revealProgress"; from: 0; to: 1; duration: Settings.motionMs * 1.4; easing.type: Easing.OutQuint }
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Settings.motionMs }
                    }
                    remove: Transition {
                        NumberAnimation { property: "revealProgress"; to: 0; duration: Settings.motionMs; easing.type: Easing.InQuint }
                        NumberAnimation { property: "opacity"; to: 0; duration: Settings.motionMs }
                    }
                    displaced: Transition {
                        NumberAnimation { property: "y"; duration: Settings.motionMs; easing.type: Easing.OutQuad }
                    }

                    delegate: Local.NotificationCard {
                        width: listView.width
                    }
                }
            }
        }
    }
}
