pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../bar"
import "../common"
import "../settings"
import "../workspaces"
import "../sysstats"
import "../wallpaper"
import "AppLibrary.js" as Library

Sheet {
    id: root
    shown: AppLauncher.shown
    title: "Library"
    centered: true
    edge: Settings.launcherEdge === "center" ? "" : Settings.launcherEdge
    initialFocusItem: search
    fitContent: false
    preferredWidth: 672; preferredHeight: 512
    onDismiss: AppLauncher.hide()
    property string category: "All"
    property string selectedId: ""
    readonly property var shortcuts: [
        {name: "Workspaces", genericName: "Switch spaces and move windows", icon: "preferences-desktop", shellAction: "workspaces"},
        {name: "Settings", genericName: "Profile, rail and appearance", icon: "preferences-system", shellAction: "settings"},
        {name: "System readings", genericName: "CPU, memory and sensors", icon: "utilities-system-monitor", shellAction: "system"},
        {name: "Quick wallpapers", genericName: "Browse your wallpaper collection", icon: "preferences-desktop-wallpaper", shellAction: "wallpapers"}
    ]
    readonly property var applications: Library.filter(shortcuts.concat([...DesktopEntries.applications.values]), search.text, category)
    readonly property var currentApp: applications[results.currentIndex] || null
    function launch(index) {
        const app = applications[index];
        if (!app) return;
        AppLauncher.hide();
        if (app.shellAction === "workspaces") WorkspacePanel.toggle();
        else if (app.shellAction === "settings") SettingsPanel.toggle();
        else if (app.shellAction === "system") SysStatsPanel.toggle();
        else if (app.shellAction === "wallpapers") QuickWallpapers.toggle();
        else app.execute();
    }
    function select(index) {
        results.currentIndex = index;
        selectedId = Library.identity(applications[index]);
        if (index >= 0) results.positionViewAtIndex(index, GridView.Contain);
    }
    function restoreSelection() {
        if (!results) return;
        select(Library.indexFor(applications, selectedId));
    }
    function resetSelection() {
        selectedId = "";
        restoreSelection();
    }
    function move(delta) {
        select(Library.move(results.currentIndex, delta, applications.length));
    }
    // Do not infer identity from currentIndex when GridView replaces its model:
    // Qt may already have reset it to zero by the time this callback runs.
    // Owned by this view: destruction cancels queued selection work.
    Timer { id: selectionRefresh; interval: 0; onTriggered: root.restoreSelection() }
    onApplicationsChanged: selectionRefresh.restart()
    onCategoryChanged: resetSelection()
    onShownChanged: if (shown) { search.text = ""; category = "All"; resetSelection(); }
    PixelField {
        id: search
        Layout.fillWidth: true
        placeholderText: "Search apps or Settings…"
        onTextChanged: { if (text) root.category = "All"; root.resetSelection(); }
        onAccepted: root.launch(results.currentIndex)
        Keys.onDownPressed: { results.forceActiveFocus(); root.move(0); }
    }
    Flow {
        Layout.fillWidth: true; spacing: 6
        Repeater {
            model: ["All", "Games", "Create", "Tools"]
            TabButton { required property string modelData; text: modelData; selected: root.category === modelData; onClicked: { search.text = ""; root.category = modelData; } }
        }
    }
    RowLayout {
        Layout.fillWidth: true; spacing: 16
        // The selected cartridge has a dedicated readout instead of a second
        // text list. The grid scrolls independently, leaving Launch reachable.
        ColumnLayout {
            visible: root.width >= 570
            Layout.preferredWidth: 190; Layout.maximumWidth: 190
            Layout.alignment: Qt.AlignTop; spacing: 12
            ConsoleSurface {
                Layout.fillWidth: true; Layout.preferredHeight: 124
                fillColor: Colors.background; raised: false
                PixelAppIcon { anchors.centerIn: parent; width: 64; height: 64; visible: !!root.currentApp; iconSource: root.currentApp ? Quickshell.iconPath(root.currentApp.icon, true) : "" }
                PixelText { x: 10; y: 8; text: String(Math.max(0, results.currentIndex + 1)).padStart(2, "0"); font.pixelSize: 11; color: Colors.textOnSurfaceVariant }
                Rectangle { anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 8; width: 4; height: 4; color: Colors.accent; visible: !!root.currentApp }
            }
            PixelText { Layout.fillWidth: true; text: root.currentApp?.name || "Nothing here"; font.family: "Pixel Operator"; font.pixelSize: 23; wrapMode: Text.Wrap; maximumLineCount: 2 }
            PixelText { Layout.fillWidth: true; visible: text.length > 0; text: root.currentApp?.genericName || root.currentApp?.comment || ""; color: Colors.textOnSurfaceVariant; wrapMode: Text.Wrap; maximumLineCount: 3 }
            PixelButton { text: "Launch  ↵"; primary: true; Layout.fillWidth: true; enabled: !!root.currentApp; onClicked: root.launch(results.currentIndex) }
        }
        GridView {
            id: results
            Layout.fillWidth: true; Layout.preferredHeight: Math.max(130, root.height - 232)
            readonly property int columns: Math.max(2, Math.floor(width / 112))
            cellWidth: Math.floor(width / columns); cellHeight: 122
            model: root.applications; currentIndex: 0; clip: true
            keyNavigationEnabled: false; activeFocusOnTab: true
            Keys.onLeftPressed: root.move(-1)
            Keys.onRightPressed: root.move(1)
            Keys.onUpPressed: if (currentIndex < columns) search.forceActiveFocus(); else root.move(-columns)
            Keys.onDownPressed: root.move(columns)
            Keys.onReturnPressed: root.launch(currentIndex)
            Keys.onEnterPressed: root.launch(currentIndex)
            Keys.onPressed: event => {
                // Typing while browsing returns to search; Ctrl/Alt shortcuts stay intact.
                if (event.text && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) && event.text.charCodeAt(0) >= 32) {
                    search.forceActiveFocus(); search.insert(search.cursorPosition, event.text); event.accepted = true;
                }
            }
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            delegate: Item {
                id: tile
                required property var modelData
                required property int index
                width: results.cellWidth; height: results.cellHeight
                PixelButton {
                    anchors.fill: parent; anchors.margins: 4
                    padding: 8; checked: results.currentIndex === tile.index
                    focusPolicy: Qt.NoFocus
                    Accessible.name: tile.modelData.name
                    onClicked: { root.select(tile.index); results.forceActiveFocus(); }
                    onDoubleClicked: root.launch(tile.index)
                    contentItem: Item {
                        Row { anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter; spacing: 3
                            Repeater { model: 3; Rectangle { width: 8; height: 2; color: Colors.outlineVariant } }
                        }
                        PixelAppIcon { anchors.horizontalCenter: parent.horizontalCenter; y: 12; width: 36; height: 36; iconSource: Quickshell.iconPath(tile.modelData.icon, true) }
                        PixelText { anchors.left: parent.left; anchors.right: parent.right; y: 55; text: tile.modelData.name; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap; maximumLineCount: 2; font.pixelSize: Settings.bodySize }
                    }
                }
            }
            PixelText { anchors.centerIn: parent; width: parent.width - 12; horizontalAlignment: Text.AlignHCenter; visible: !results.count; text: "No matching apps.\nTry All or another search."; wrapMode: Text.Wrap; color: Colors.textOnSurfaceVariant }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        PixelText { text: Math.max(0, results.currentIndex + 1) + " / " + root.applications.length; color: Colors.accent }
        Item { Layout.fillWidth: true }
    }
    PixelButton { visible: root.width < 570; text: "Launch  ↵"; Layout.fillWidth: true; primary: true; enabled: !!root.currentApp; onClicked: root.launch(results.currentIndex) }
}
