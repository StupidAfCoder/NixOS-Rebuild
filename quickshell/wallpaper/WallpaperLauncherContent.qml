pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../bar"
import "../common"
import "../common/CollectionState.js" as CollectionState

Sheet {
    id: root
    shown: WallpaperLauncher.shown
    title: "Wallpaper studio"
    subtitle: Settings.previewMode ? "Preview" : ""
    centered: true
    initialFocusItem: search
    preferredWidth: 820; preferredHeight: 790
    onDismiss: WallpaperLauncher.hide()
    property string selectedPath: ""
    property string recipe: Settings.recipe
    property real tone: Settings.tone
    property real saturation: Settings.saturation
    property string sourcePreference: Settings.sourcePreference
    property bool confirmAppSync: false
    property bool confirmTrash: false
    property bool advanced: false
    readonly property bool busy: WallpaperBackend.applying || WallpaperBackend.tryingColors || WallpaperBackend.syncingApps || WallpaperBackend.trashing
    readonly property var filtered: WallpaperBackend.wallpapers.filter(w => w.name.toLowerCase().includes(search.text.toLowerCase()))
    function preview() {
        if (!shown) return;
        if (selectedPath) WallpaperBackend.preview(selectedPath, recipe, tone, saturation, sourcePreference, Settings.contrast);
        else WallpaperBackend.cancelPreview();
    }
    Connections {
        target: WallpaperBackend
        function onWallpaperTrashed(path) { if (root.selectedPath === path) root.selectedPath = ""; }
    }
    Connections { target: Settings; function onContrastChanged() { root.preview(); } }
    function select(index) {
        if (index >= 0 && index < filtered.length) {
            gallery.currentIndex = index; selectedPath = filtered[index].path;
            gallery.positionViewAtIndex(index, GridView.Contain);
        }
    }
    function move(step) {
        select(CollectionState.boundedIndex(filtered.length, gallery.currentIndex + step));
    }
    onFilteredChanged: Qt.callLater(function() { gallery.currentIndex = CollectionState.indexFor(root.filtered, root.selectedPath, ""); })
    onSelectedPathChanged: { confirmAppSync = false; confirmTrash = false; preview(); }
    onRecipeChanged: preview()
    onToneChanged: preview()
    onSaturationChanged: preview()
    onSourcePreferenceChanged: preview()
    onShownChanged: if (!shown) { confirmAppSync = false; confirmTrash = false; } else {
        recipe = Settings.recipe; tone = Settings.tone; saturation = Settings.saturation; sourcePreference = Settings.sourcePreference;
        advanced = ["balanced", "wallpaper", "black", "paper"].indexOf(recipe) < 0;
        if (WallpaperLauncher.requestedPath) {
            selectedPath = WallpaperLauncher.requestedPath;
            WallpaperLauncher.requestedPath = "";
        } else selectedPath = (Settings.previewMode ? WallpaperBackend.previewPath : "") || WallpaperBackend.currentPath || selectedPath;
        gallery.currentIndex = CollectionState.indexFor(filtered, selectedPath, "");
        if (gallery.currentIndex >= 0) gallery.positionViewAtIndex(gallery.currentIndex, GridView.Contain);
        preview();
    }
    RowLayout {
        Layout.fillWidth: true
        PixelField { id: search; Layout.fillWidth: true; placeholderText: "Search collection…"; Keys.onDownPressed: { gallery.forceActiveFocus(); root.move(0); } }
        PixelButton { text: "Refresh"; enabled: !WallpaperBackend.scanning; onClicked: WallpaperBackend.refresh() }
    }
    // A full-width contact sheet, not a tall empty left column.
    GridView {
        id: gallery
        Layout.fillWidth: true; Layout.preferredHeight: 204
        readonly property int columns: Math.max(2, Math.floor((width - 12) / 145))
        cellWidth: Math.floor((width - 12) / columns); cellHeight: 102
        pressDelay: 120
        model: root.filtered; clip: true; keyNavigationEnabled: false; activeFocusOnTab: true
        Keys.onLeftPressed: root.move(-1)
        Keys.onRightPressed: root.move(1)
        Keys.onUpPressed: root.move(-columns)
        Keys.onDownPressed: root.move(columns)
        // Home/End/Page keys have no dedicated Keys signals in Qt Quick.
        Keys.onPressed: event => {
            if (event.key === Qt.Key_PageUp) root.move(-gallery.columns * 2);
            else if (event.key === Qt.Key_PageDown) root.move(gallery.columns * 2);
            else if (event.key === Qt.Key_Home) root.select(0);
            else if (event.key === Qt.Key_End) root.select(gallery.count - 1);
            else { event.accepted = false; return; }
            event.accepted = true;
        }
        Keys.onReturnPressed: root.select(currentIndex)
        Keys.onEnterPressed: root.select(currentIndex)
        ScrollBar.vertical: CollectionScrollBar { Accessible.name: "Wallpaper collection" }
        delegate: Item {
            id: tile
            required property var modelData
            required property int index
            width: gallery.cellWidth; height: gallery.cellHeight
            PixelButton {
                anchors.fill: parent; anchors.margins: 3; padding: 4; topPadding: 4; bottomPadding: 4
                focusPolicy: Qt.NoFocus; checked: root.selectedPath === tile.modelData.path
                Accessible.name: tile.modelData.name
                contentItem: Item {
                    Image { anchors.fill: parent; anchors.bottomMargin: 22; source: Settings.fileUrl(tile.modelData.path); asynchronous: true; sourceSize.width: 320; sourceSize.height: 180; fillMode: Image.PreserveAspectCrop; clip: true }
                    PixelText { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; text: tile.modelData.name }
                }
                onClicked: { root.select(tile.index); gallery.forceActiveFocus(); }
            }
        }
        PixelText { anchors.centerIn: parent; visible: !gallery.count; text: WallpaperBackend.scanning ? "Reading collection…" : "No matching wallpapers. Choose a folder in Settings → Profile."; width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap; color: Colors.textOnSurfaceVariant }
    }
    GridLayout {
        Layout.fillWidth: true; columns: root.width >= 660 ? 2 : 1; columnSpacing: 18; rowSpacing: 12
        ColumnLayout {
            Layout.fillWidth: true; Layout.preferredWidth: 238; Layout.alignment: Qt.AlignTop; spacing: 8
            Image {
                Layout.fillWidth: true; Layout.preferredHeight: 140
                source: Settings.fileUrl(root.selectedPath); asynchronous: true; sourceSize.width: 640; sourceSize.height: 360
                fillMode: Image.PreserveAspectFit
                PixelText { anchors.centerIn: parent; visible: !root.selectedPath; text: "Choose a wallpaper" }
            }
            PixelText { Layout.fillWidth: true; text: root.selectedPath.split("/").pop() || "Nothing selected" }
            RowLayout {
                Layout.fillWidth: true; spacing: 4
                Repeater {
                    model: ["background", "surface_container", "outline", "accent", "on_surface"]
                    Rectangle { required property string modelData; Layout.fillWidth: true; implicitHeight: 12; color: WallpaperBackend.previewColors[modelData] || Colors.background }
                }
            }
            PixelButton {
                Layout.fillWidth: true; primary: true; enabled: !!root.selectedPath && !root.busy
                text: Settings.previewMode ? (WallpaperBackend.tryingColors ? "Trying…" : "Try in preview") : WallpaperBackend.applying ? "Applying…" : "Apply wallpaper + palette"
                onClicked: Settings.previewMode ? WallpaperBackend.tryColors(root.selectedPath, root.recipe, root.tone, root.saturation, root.sourcePreference, Settings.contrast) : WallpaperBackend.apply(root.selectedPath, root.recipe, root.tone, root.saturation, root.sourcePreference, Settings.contrast)
            }
        }
        ColumnLayout {
            Layout.fillWidth: true; Layout.preferredWidth: 460; Layout.alignment: Qt.AlignTop; spacing: 8
            Flow {
                Layout.fillWidth: true; spacing: 6
                Repeater {
                    model: [{id:"balanced",label:"Balanced"},{id:"wallpaper",label:"Tinted"},{id:"black",label:"True black"},{id:"paper",label:"Paper"}]
                    TabButton { required property var modelData; text: modelData.label; selected: root.recipe === modelData.id; onClicked: root.recipe = modelData.id }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                PixelText { text: "Tone"; Layout.preferredWidth: 68 }
                PixelSlider { Layout.fillWidth: true; from: -15; to: 15; stepSize: 1; value: root.tone; onMoved: root.tone = value }
                PixelText { text: Math.round(root.tone); Layout.preferredWidth: 28; horizontalAlignment: Text.AlignRight }
            }
            RowLayout {
                Layout.fillWidth: true
                PixelText { text: "Intensity"; Layout.preferredWidth: 68 }
                PixelSlider { Layout.fillWidth: true; from: 0; to: 1.6; stepSize: .05; value: root.saturation; onMoved: root.saturation = value }
                PixelText { text: Math.round(root.saturation * 100) + "%"; Layout.preferredWidth: 36; horizontalAlignment: Text.AlignRight }
            }
            PixelButton { text: root.advanced ? "Less ↑" : "Advanced ↓"; checked: root.advanced; onClicked: root.advanced = !root.advanced }
            Flow {
                Layout.fillWidth: true; spacing: 8
                PixelButton {
                    text: WallpaperBackend.syncingApps ? "Syncing…" : root.confirmAppSync ? "Confirm live recoloring" : "Sync live app colors…"
                    enabled: !!root.selectedPath && !root.busy
                    onClicked: { if (root.confirmAppSync) { WallpaperBackend.syncLiveApps(root.selectedPath); root.confirmAppSync = false; } else root.confirmAppSync = true; }
                }
                PixelButton { text: WallpaperBackend.trashing ? "Moving…" : root.confirmTrash ? "Confirm Trash" : "Trash…"; danger: root.confirmTrash; enabled: !!root.selectedPath && !root.busy; onClicked: { if (root.confirmTrash) { WallpaperBackend.trash(root.selectedPath); root.confirmTrash = false; } else root.confirmTrash = true; } }
                PixelButton { visible: root.confirmAppSync || root.confirmTrash; text: "Cancel"; onClicked: { root.confirmAppSync = false; root.confirmTrash = false; } }
            }
            PixelText { visible: WallpaperBackend.previewBusy; text: "Generating preview…"; color: Colors.textOnSurfaceVariant }
        }
    }
    Flow {
        visible: root.advanced; Layout.fillWidth: true; spacing: 6
        Repeater { model: ["neutral", "tonal", "expressive", "mono"]; TabButton { required property string modelData; text: modelData; selected: root.recipe === modelData; onClicked: root.recipe = modelData } }
    }
    Flow {
        visible: root.advanced; Layout.fillWidth: true; spacing: 6
        Repeater { model: ["representative", "dominant", "colorful"]; PixelButton { required property string modelData; text: modelData; checked: root.sourcePreference === modelData; onClicked: root.sourcePreference = modelData } }
    }
    PixelText { visible: root.confirmAppSync; Layout.fillWidth: true; text: "Writes LIVE Wallust templates and requests Firefox / terminal recoloring, even in preview. This is separate from the shell palette above. The wallpaper is not changed."; wrapMode: Text.Wrap; elide: Text.ElideNone; color: Colors.warning }
    PixelText { visible: !!WallpaperBackend.appSyncMessage; Layout.fillWidth: true; text: WallpaperBackend.appSyncMessage; wrapMode: Text.Wrap; elide: Text.ElideNone; color: Colors.textOnSurfaceVariant }
    PixelText { Layout.fillWidth: true; visible: !!text; text: WallpaperBackend.lastError; color: Colors.error; wrapMode: Text.Wrap; elide: Text.ElideNone }
}
