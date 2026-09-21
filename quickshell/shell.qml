//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import QtQuick
import "notifications"
import "bar"
import "wallpaper"
import "./launcher"
import "common"
import "osd"

ShellRoot {
    id: root
    FeedbackOsd {}
    // Populate the mascot cache on first launch too, not only after a theme switch.
    Process {
        command: ["bash", Settings.repo + "quickshell/bar/scripts/generate-theme-assets.sh", Settings.themeFile]
        running: true
    }

    // Instantiate our custom notification server framework
    NotificationManager {
        id: notificationManager
    }

    // Bar + border are now drawn together in one window per screen
    // (see bar/ShellFrame.qml) so they can't ever drift apart into a
    // visible seam the way two separately-positioned layer-shell
    // windows could.
    ShellFrame {
        barWidth: Settings.barWidth
        borderThickness: Settings.frameWidth
        frameColor: Colors.background
        accentColor: Colors.accent
    }


}
