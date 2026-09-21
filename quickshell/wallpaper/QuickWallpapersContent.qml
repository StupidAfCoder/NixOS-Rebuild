pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../common"
import "../bar"
import "../settings"
import "../common/CollectionState.js" as CollectionState

Sheet {
    id: root
    shown: QuickWallpapers.shown
    title: "Wallpapers"
    subtitle: Settings.previewMode ? "Preview colors only · live apps are unchanged" : "Choose a scene · the desktop follows"
    edge: "right"
    preferredWidth: 820; preferredHeight: 390
    initialFocusItem: carousel
    onDismiss: QuickWallpapers.hide()
    readonly property bool busy: WallpaperBackend.applying || WallpaperBackend.tryingColors || WallpaperBackend.syncingApps
    property string selectedPath: ""
    readonly property string appliedPath: Settings.previewMode ? WallpaperBackend.previewPath || WallpaperBackend.currentPath : WallpaperBackend.currentPath
    function restoreSelection() {
        carousel.currentIndex = CollectionState.indexFor(WallpaperBackend.wallpapers, selectedPath, appliedPath);
        if (carousel.currentIndex >= 0) selectedPath = WallpaperBackend.wallpapers[carousel.currentIndex].path;
    }
    function move(step) {
        carousel.currentIndex = CollectionState.boundedIndex(carousel.count, carousel.currentIndex + step);
        if (carousel.currentIndex >= 0) selectedPath = WallpaperBackend.wallpapers[carousel.currentIndex].path;
    }
    Connections {
        target: WallpaperBackend
        function onWallpapersChanged() { if (root.shown) Qt.callLater(function() { if (root.shown) root.restoreSelection(); }); }
    }
    function choose(index) {
        const wallpaper = WallpaperBackend.wallpapers[index];
        if (!wallpaper || busy) return;
        carousel.currentIndex = index;
        selectedPath = wallpaper.path;
        if (Settings.previewMode) WallpaperBackend.tryColors(wallpaper.path, Settings.recipe, Settings.tone, Settings.saturation, Settings.sourcePreference, Settings.contrast);
        else WallpaperBackend.apply(wallpaper.path, Settings.recipe, Settings.tone, Settings.saturation, Settings.sourcePreference, Settings.contrast);
    }
    onShownChanged: if (shown) { selectedPath = appliedPath; restoreSelection(); }
    ListView {
        id: carousel
        Layout.fillWidth: true; Layout.preferredHeight: 210
        orientation: ListView.Horizontal; spacing: 10; clip: true
        model: WallpaperBackend.wallpapers
        snapMode: ListView.SnapToItem
        highlightRangeMode: ListView.ApplyRange
        preferredHighlightBegin: Math.max(0, (width - 260) / 2)
        preferredHighlightEnd: preferredHighlightBegin + 260
        highlightMoveDuration: Settings.motionMs
        Keys.onLeftPressed: root.move(-1)
        Keys.onRightPressed: root.move(1)
        Keys.onReturnPressed: root.choose(currentIndex)
        Keys.onEnterPressed: root.choose(currentIndex)
        delegate: Item {
            id: tile
            required property var modelData
            required property int index
            readonly property bool selected: carousel.currentIndex === index
            width: selected ? 260 : 160; height: 210
            Behavior on width { NumberAnimation { duration: Settings.motionMs } }
            Button {
                anchors.centerIn: parent; width: parent.width; height: tile.selected ? 210 : 178
                Behavior on height { NumberAnimation { duration: Settings.motionMs } }
                padding: 3; enabled: !root.busy; focusPolicy: Qt.NoFocus
                Accessible.name: "Apply " + tile.modelData.name
                background: Rectangle { color: Colors.background; border.width: tile.selected ? 2 : 0; border.color: Colors.accent }
                contentItem: Image { source: Settings.fileUrl(tile.modelData.path); asynchronous: true; sourceSize.width: 400; fillMode: Image.PreserveAspectCrop }
                onClicked: { root.choose(tile.index); carousel.forceActiveFocus(); }
            }
        }
        MouseArea {
            anchors.fill: parent; acceptedButtons: Qt.NoButton
            onWheel: event => { const delta = event.angleDelta.y || event.angleDelta.x || event.pixelDelta.y || event.pixelDelta.x; if (delta) root.move(delta < 0 ? 1 : -1); event.accepted = true; }
        }
        PixelText { visible: carousel.count === 0; anchors.centerIn: parent; text: WallpaperBackend.scanning ? "Reading collection…" : "No wallpapers in this folder."; color: Colors.textOnSurfaceVariant }
    }
    RowLayout {
        Layout.fillWidth: true
        IconButton { iconName: "chevron-left.svg"; hint: "Previous wallpaper"; enabled: carousel.currentIndex > 0; onClicked: root.move(-1) }
        PixelText { Layout.fillWidth: true; text: root.busy ? "Applying colors…" : WallpaperBackend.wallpapers[carousel.currentIndex]?.name || "Choose a wallpaper folder in Settings" }
        IconButton { iconName: "chevron-right.svg"; hint: "Next wallpaper"; enabled: carousel.currentIndex < carousel.count - 1; onClicked: root.move(1) }
        PixelButton { text: "Adjust colors"; onClicked: { QuickWallpapers.hide(); WallpaperLauncher.openFor(root.selectedPath); } }
    }
    PixelButton { visible: carousel.count === 0; text: "Choose folder…"; onClicked: { QuickWallpapers.hide(); SettingsPanel.toggle(); } }
    PixelText { Layout.fillWidth: true; visible: !!WallpaperBackend.lastError; text: WallpaperBackend.lastError; wrapMode: Text.Wrap; elide: Text.ElideNone; color: Colors.error }
}
