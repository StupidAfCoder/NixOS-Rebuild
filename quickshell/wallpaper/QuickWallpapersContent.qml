pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import "../common"
import "../bar"
import "../common/CollectionState.js" as CollectionState

// Deliberately not a Sheet: only the photographs float over the desktop.
FocusScope {
    id: root
    property bool shown: QuickWallpapers.shown
    property real reveal: shown ? 1 : 0
    width: Math.max(1, Math.min(960, parent.width - Settings.barWidth - 40))
    height: Math.min(330, parent.height - Settings.frameWidth * 2 - 40)
    x: Settings.barWidth + (parent.width - Settings.barWidth - width) / 2 + 28 * (1 - reveal)
    y: Math.round((parent.height - height) / 2)
    visible: shown || reveal > 0; enabled: shown; opacity: reveal
    Behavior on reveal { NumberAnimation { duration: Settings.motionMs; easing.type: Easing.OutCubic } }
    readonly property bool busy: WallpaperBackend.applying || WallpaperBackend.tryingColors || WallpaperBackend.syncingApps || WallpaperBackend.trashing
    property string selectedPath: ""
    readonly property string appliedPath: Settings.previewMode ? WallpaperBackend.previewPath || WallpaperBackend.currentPath : WallpaperBackend.currentPath
    function restoreSelection() {
        carousel.userScrolling = false;
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
        carousel.currentIndex = index; selectedPath = wallpaper.path;
        if (Settings.previewMode) WallpaperBackend.tryColors(wallpaper.path, Settings.recipe, Settings.tone, Settings.saturation, Settings.sourcePreference, Settings.contrast);
        else WallpaperBackend.apply(wallpaper.path, Settings.recipe, Settings.tone, Settings.saturation, Settings.sourcePreference, Settings.contrast);
    }
    onShownChanged: if (shown) {
        selectedPath = appliedPath; restoreSelection();
        Qt.callLater(function() { if (root.shown) carousel.forceActiveFocus(); });
    }
    Keys.onEscapePressed: QuickWallpapers.hide()
    ListView {
        id: carousel
        width: parent.width; height: Math.max(80, parent.height - 54)
        orientation: ListView.Horizontal; spacing: 16; clip: true
        model: WallpaperBackend.wallpapers
        snapMode: ListView.SnapToItem
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: (width - 300) / 2
        preferredHighlightEnd: preferredHighlightBegin + 300
        highlightMoveDuration: Settings.motionMs
        property bool userScrolling: false
        onDraggingChanged: if (dragging) userScrolling = true
        onMovementEnded: if (userScrolling) {
            userScrolling = false;
            if (currentIndex >= 0 && currentIndex < WallpaperBackend.wallpapers.length) root.selectedPath = WallpaperBackend.wallpapers[currentIndex].path;
        }
        Keys.onLeftPressed: root.move(-1)
        Keys.onRightPressed: root.move(1)
        Keys.onUpPressed: root.move(-1)
        Keys.onDownPressed: root.move(1)
        Keys.onReturnPressed: root.choose(currentIndex)
        Keys.onEnterPressed: root.choose(currentIndex)
        delegate: Item {
            id: tile
            required property var modelData
            required property int index
            readonly property bool selected: carousel.currentIndex === index
            width: 300; height: carousel.height
            PixelButton {
                anchors.centerIn: parent; width: tile.selected ? 300 : 250; height: tile.selected ? parent.height : parent.height * .8
                Behavior on width { NumberAnimation { duration: Settings.motionMs } }
                Behavior on height { NumberAnimation { duration: Settings.motionMs } }
                padding: 3; topPadding: 3; bottomPadding: 3; focusPolicy: Qt.NoFocus
                enabled: !root.busy
                Accessible.name: "Apply " + tile.modelData.name
                background: ConsoleSurface { raised: false; fillColor: Colors.background; edgeColor: tile.selected ? Colors.accent : Colors.outlineVariant }
                contentItem: Image { source: Settings.fileUrl(tile.modelData.path); asynchronous: true; sourceSize.width: 600; sourceSize.height: 480; fillMode: Image.PreserveAspectCrop; clip: true }
                onClicked: { root.choose(tile.index); carousel.forceActiveFocus(); }
            }
        }
        MouseArea {
            anchors.fill: parent; acceptedButtons: Qt.NoButton
            onWheel: event => { const delta = event.angleDelta.y || event.angleDelta.x || event.pixelDelta.y || event.pixelDelta.x; if (delta) root.move(delta < 0 ? 1 : -1); event.accepted = true; }
        }
    }
    // Outlined text remains legible without a panel or a translucent scrim.
    PixelText {
        anchors.top: carousel.bottom; anchors.topMargin: 10; width: parent.width
        horizontalAlignment: Text.AlignHCenter; style: Text.Outline; styleColor: "#000000"; color: "#ffffff"
        text: WallpaperBackend.lastError || (root.busy ? "Applying…" : !carousel.count ? (WallpaperBackend.scanning ? "Reading collection…" : "Choose a collection in Settings → Profile.") : root.selectedPath.split("/").pop())
    }
    PixelText {
        anchors.bottom: parent.bottom; width: parent.width
        horizontalAlignment: Text.AlignHCenter; style: Text.Outline; styleColor: "#000000"; color: "#ffffff"; font.pixelSize: 12
        text: (Settings.previewMode ? "Preview colors only · " : "") + "← → browse · Enter or click applies · Esc closes"
    }
}
