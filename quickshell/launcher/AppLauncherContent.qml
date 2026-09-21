import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../bar"
import "../common"

Sheet {
    id: root
    shown: AppLauncher.shown
    title: "Launch"
    subtitle: "A name is all you need."
    centered: true
    initialFocusItem: search
    preferredWidth: 540
    preferredHeight: 530
    onDismiss: AppLauncher.hide()
    property var applications: {
        const q = search.text.trim().toLowerCase();
        return [...DesktopEntries.applications.values].filter(e => e && !e.noDisplay && e.name &&
            (!q || (e.name + " " + (e.genericName || "") + " " + (e.comment || "")).toLowerCase().includes(q)))
            .sort((a,b) => {
                const rank = Number(!a.name.toLowerCase().startsWith(q)) - Number(!b.name.toLowerCase().startsWith(q));
                return rank || a.name.localeCompare(b.name);
            });
    }
    function launch(index) { const app = applications[index]; if (app) { app.execute(); AppLauncher.hide(); } }
    function move(delta) { results.currentIndex = Math.max(0, Math.min(applications.length - 1, results.currentIndex + delta)); results.positionViewAtIndex(results.currentIndex, ListView.Contain); }
    onShownChanged: if (shown) { search.text = ""; results.currentIndex = 0;  }
    PixelField {
        id: search
        Layout.fillWidth: true; placeholderText: "Type to launch…"
        onTextChanged: results.currentIndex = 0
        onAccepted: root.launch(results.currentIndex)
        Keys.onDownPressed: root.move(1)
        Keys.onUpPressed: root.move(-1)
    }
    ListView {
        id: results
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(330, Math.max(100, root.height - 210))
        clip: true; spacing: 4
        model: root.applications
        currentIndex: 0
        ScrollBar.vertical: ScrollBar {}
        delegate: Rectangle {
            id: row
            required property var modelData
            required property int index
            width: results.width; height: 58
            color: results.currentIndex === index ? Colors.surfaceContainerHigh : "transparent"
            Rectangle { width: 3; height: parent.height; color: Colors.accent; visible: results.currentIndex === row.index }
            RowLayout {
                anchors.fill: parent; anchors.margins: 10; spacing: 12
                PixelAppIcon { Layout.preferredWidth: 30; Layout.preferredHeight: 30; iconSource: Quickshell.iconPath(row.modelData.icon, "application-x-executable") }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 3
                    PixelText { Layout.fillWidth: true; text: row.modelData.name }
                    PixelText { Layout.fillWidth: true; text: row.modelData.genericName || row.modelData.comment || "Application"; color: Colors.textOnSurfaceVariant }
                }
                PixelText { text: "↵"; visible: results.currentIndex === row.index; color: Colors.accent }
            }
            MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: results.currentIndex = row.index; onClicked: root.launch(row.index) }
        }
        PixelText { anchors.centerIn: parent; visible: root.applications.length === 0; text: "No matches. Try another name." }
    }
    PixelText { text: "↑ ↓ navigate   /   Enter launch   /   Esc close"; color: Colors.textOnSurfaceVariant; Layout.fillWidth: true; wrapMode: Text.Wrap }
}
