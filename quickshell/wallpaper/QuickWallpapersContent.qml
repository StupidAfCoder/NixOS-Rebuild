pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import "../common/PopupGeometry.js" as Geometry
import "../common"
import "../bar"
import "../common/CollectionState.js" as CollectionState

// Deliberately not a Sheet: only the photographs float over the desktop.
FocusScope {
    id: root
    property bool shown: QuickWallpapers.shown
    property real reveal: shown ? 1 : 0
    readonly property var area: Geometry.bounds(parent.width, parent.height, Settings.desktopInsets, 20)
    width: Math.max(1, Math.min(960, area.width))
    height: Math.max(1, Math.min(330, area.height))
    x: area.x + (area.width - width) / 2 + 28 * (1 - reveal)
    y: Math.round(area.y + (area.height - height) / 2)
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
    function scrubTo(index) {
        carousel.cancelFlick(); carousel.userScrolling = false;
        carousel.currentIndex = CollectionState.boundedIndex(carousel.count, index);
        if (carousel.currentIndex >= 0) {
            selectedPath = WallpaperBackend.wallpapers[carousel.currentIndex].path;
            carousel.positionViewAtIndex(carousel.currentIndex, ListView.Center);
        }
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
        width: parent.width; height: Math.max(1, parent.height - 66)
        pressDelay: 120
        orientation: ListView.Horizontal; spacing: 16; clip: true
        model: WallpaperBackend.wallpapers
        snapMode: ListView.SnapToItem
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: (width - 300) / 2
        preferredHighlightEnd: preferredHighlightBegin + 300
        highlightMoveDuration: scrub.pressed ? 0 : Settings.motionMs
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
        // Home/End/Page keys have no dedicated Keys signals in Qt Quick.
        Keys.onPressed: event => {
            if (event.key === Qt.Key_PageUp) root.scrubTo(carousel.currentIndex - 10);
            else if (event.key === Qt.Key_PageDown) root.scrubTo(carousel.currentIndex + 10);
            else if (event.key === Qt.Key_Home) root.scrubTo(0);
            else if (event.key === Qt.Key_End) root.scrubTo(carousel.count - 1);
            else { event.accepted = false; return; }
            event.accepted = true;
        }
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
                onClicked: { if (!carousel.dragging && !carousel.flicking) root.choose(tile.index); carousel.forceActiveFocus(); }
            }
        }
        MouseArea {
            anchors.fill: parent; acceptedButtons: Qt.NoButton
            onWheel: event => { const delta = event.angleDelta.y || event.angleDelta.x || event.pixelDelta.y || event.pixelDelta.x; if (delta) root.move(delta < 0 ? 3 : -3); event.accepted = true; }
        }
    }
    // Outlined text remains legible without a panel or a translucent scrim.
    PixelText {
        anchors.top: carousel.bottom; anchors.topMargin: 10; width: parent.width
        horizontalAlignment: Text.AlignHCenter; style: Text.Outline; styleColor: "#000000"; color: "#ffffff"
        text: WallpaperBackend.lastError || (root.busy ? "Applying…" : !carousel.count ? (WallpaperBackend.scanning ? "Reading collection…" : "Choose a collection in Settings → Profile.") : ((Settings.previewMode ? "Preview · " : "") + (WallpaperBackend.wallpapers[carousel.currentIndex]?.name || "")))
    }
    PixelSlider {
        id: scrub
        anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(420, parent.width - 32); height: 24
        visible: carousel.count > 1
        from: 0; to: Math.max(1, carousel.count - 1); stepSize: 1
        value: Math.max(0, carousel.currentIndex)
        Accessible.name: "Wallpaper position"
        onMoved: root.scrubTo(Math.round(value))
        onPressedChanged: if (!pressed) carousel.forceActiveFocus()
        Keys.onReturnPressed: root.choose(carousel.currentIndex)
        Keys.onEnterPressed: root.choose(carousel.currentIndex)
        background: Rectangle {
            x: scrub.leftPadding; y: scrub.topPadding + scrub.availableHeight / 2 - 2
            width: scrub.availableWidth; height: 4; color: "#b3000000"
            Rectangle { width: scrub.visualPosition * parent.width; height: 4; color: Colors.accent }
        }
    }
}
