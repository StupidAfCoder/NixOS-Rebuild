pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../bar"
import "../common"
import "../settings"
import "../sysstats"
import "../wallpaper"

Sheet {
    id: root
    shown: AppLauncher.shown
    title: "Library"
    centered: true
    edge: Settings.launcherEdge === "center" ? "" : Settings.launcherEdge
    initialFocusItem: search
    fitContent: false
    preferredWidth: 480
    preferredHeight: 480
    onDismiss: AppLauncher.hide()
    property var applications: {
        const q = search.text.trim().toLowerCase();
        const shortcuts = [
            {name: "Settings", genericName: "Your corner preferences", icon: "preferences-system", shellAction: "settings"},
            {name: "System readings", genericName: "CPU memory sensors", icon: "utilities-system-monitor", shellAction: "system"},
            {name: "Quick wallpapers", genericName: "Browse wallpaper carousel", icon: "preferences-desktop-wallpaper", shellAction: "wallpapers"}
        ];
        return shortcuts.concat([...DesktopEntries.applications.values]).filter(e => e && !e.noDisplay && e.name &&
            (!q || (e.name + " " + (e.genericName || "") + " " + (e.comment || "")).toLowerCase().includes(q)))
            .sort((a,b) => Number(!a.name.toLowerCase().startsWith(q)) - Number(!b.name.toLowerCase().startsWith(q)) || a.name.localeCompare(b.name));
    }
    function launch(index) { const app = applications[index]; if (app) { AppLauncher.hide();
        if (app.shellAction === "settings") SettingsPanel.toggle();
        else if (app.shellAction === "system") SysStatsPanel.toggle();
        else if (app.shellAction === "wallpapers") QuickWallpapers.toggle();
        else app.execute(); } }
    function move(delta) {
        results.currentIndex = Math.max(0, Math.min(applications.length - 1, results.currentIndex + delta));
        results.positionViewAtIndex(results.currentIndex, ListView.Contain);
    }
    onShownChanged: if (shown) { search.text = ""; results.currentIndex = 0; }
    PixelField {
        id: search
        Layout.fillWidth: true
        placeholderText: "Find an app"
        onTextChanged: results.currentIndex = 0
        onAccepted: root.launch(results.currentIndex)
        Keys.onDownPressed: root.move(1)
        Keys.onUpPressed: root.move(-1)
    }
    ListView {
        id: results
        Layout.fillWidth: true
        Layout.preferredHeight: Math.max(100, root.height - 200)
        model: root.applications
        currentIndex: 0
        spacing: 4; clip: true
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        delegate: Button {
            id: row
            required property var modelData
            required property int index
            width: results.width; height: 56; padding: 10
            hoverEnabled: true
            Accessible.name: modelData.name
            onClicked: root.launch(index)
            onHoveredChanged: if (hovered) results.currentIndex = index
            Keys.onDownPressed: root.move(1)
            Keys.onUpPressed: root.move(-1)
            background: Rectangle {
                color: results.currentIndex === row.index ? Colors.surfaceContainerHigh : "transparent"
                Rectangle { width: 2; height: 16; anchors.verticalCenter: parent.verticalCenter; color: Colors.accent; visible: results.currentIndex === row.index }
                border.width: row.activeFocus ? 1 : 0; border.color: Colors.accent
            }
            contentItem: RowLayout {
                spacing: 16
                PixelAppIcon { Layout.preferredWidth: 28; Layout.preferredHeight: 28; iconSource: Quickshell.iconPath(row.modelData.icon, true) }
                PixelText { text: row.modelData.name; Layout.fillWidth: true; font.pixelSize: Settings.bodySize + 2 }
                PixelText { visible: results.currentIndex === row.index; text: "Enter"; color: Colors.textOnSurfaceVariant }
            }
        }
        PixelText { anchors.centerIn: parent; visible: root.applications.length === 0; text: "No matching apps."; color: Colors.textOnSurfaceVariant }
    }
    RowLayout {
        Layout.fillWidth: true
        PixelText { text: root.applications.length + " apps"; Layout.fillWidth: true; color: Colors.textOnSurfaceVariant }
        PixelText { text: "Esc to close"; color: Colors.textOnSurfaceVariant }
    }
}
