//@ pragma UseQApplication
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

    // Bar + border are now drawn together in one window per screen
    // (see bar/ShellFrame.qml) so they can't ever drift apart into a
    // visible seam the way two separately-positioned layer-shell
    // windows could.
    ShellFrame {
        barWidth: 40
        borderThickness: 10
        frameColor: "#232939"
        accentColor: "#565f89"
    }
}
