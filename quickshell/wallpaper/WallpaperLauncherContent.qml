import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../bar"
import "../common"

Sheet {
    id: root
    property int topOffset: 0
    shown: WallpaperLauncher.shown
    title: "Wallpapers"
    subtitle: "Preview first. Apply when it feels right."
    centered: true
    initialFocusItem: search
    preferredWidth: 860
    preferredHeight: 660
    onDismiss: WallpaperLauncher.hide()
    property string selectedPath: ""
    property string recipe: Settings.recipe
    property real tone: Settings.tone
    property real saturation: Settings.saturation
    property string sourcePreference: Settings.sourcePreference
    property bool confirmAppSync: false
    property bool confirmTrash: false
    readonly property var filtered: WallpaperBackend.wallpapers.filter(w => w.name.toLowerCase().includes(search.text.toLowerCase()))
    function preview() {
        if (selectedPath) WallpaperBackend.preview(selectedPath, recipe, tone, saturation, sourcePreference, Settings.contrast);
    }
    onSelectedPathChanged: { confirmAppSync = false; confirmTrash = false; preview(); }
    onRecipeChanged: preview()
    onToneChanged: preview()
    onSaturationChanged: preview()
    onSourcePreferenceChanged: preview()
    onShownChanged: if (!shown) confirmAppSync = false; else {
        recipe = Settings.recipe; tone = Settings.tone; saturation = Settings.saturation; sourcePreference = Settings.sourcePreference;
        if (!selectedPath) selectedPath = WallpaperBackend.currentPath;
        preview();

    }
    PixelField { id: search; Layout.fillWidth: true; placeholderText: "Search your collection…" }
    GridLayout {
        Layout.fillWidth: true
        columns: root.width > 660 ? 2 : 1
        columnSpacing: 20; rowSpacing: 16
        ColumnLayout {
            Layout.fillWidth: true; Layout.preferredWidth: 440; Layout.alignment: Qt.AlignTop
            GridView {
                id: gallery
                Layout.fillWidth: true
                Layout.preferredHeight: root.width > 660 ? 400 : 240
                clip: true
                model: root.filtered
                cellWidth: width / Math.max(2, Math.floor(width / 145))
                cellHeight: cellWidth * .65 + 32
                keyNavigationEnabled: true
                activeFocusOnTab: true
                highlightMoveDuration: Settings.motionMs
                Keys.onReturnPressed: if (currentIndex >= 0 && currentIndex < root.filtered.length) root.selectedPath = root.filtered[currentIndex].path
                ScrollBar.vertical: ScrollBar {}
                delegate: Item {
                    required property var modelData
                    required property int index
                    width: gallery.cellWidth; height: gallery.cellHeight
                    Rectangle {
                        anchors.fill: parent; anchors.margins: 5
                        color: Colors.background
                        border.width: root.selectedPath === modelData.path ? 2 : 1
                        border.color: root.selectedPath === modelData.path || (gallery.activeFocus && gallery.currentIndex === index) ? Colors.accent : Colors.outlineVariant
                        Image {
                            anchors.fill: parent; anchors.margins: 3; anchors.bottomMargin: 28
                            source: Settings.fileUrl(modelData.path)
                            asynchronous: true; sourceSize.width: 320
                            fillMode: Image.PreserveAspectCrop
                        }
                        PixelText { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 7; text: modelData.name }
                        MouseArea { anchors.fill: parent; onClicked: { gallery.currentIndex = index; root.selectedPath = modelData.path; } }
                    }
                }
            }
            PixelText { Layout.fillWidth: true; text: WallpaperBackend.scanning ? "Reading collection…" : root.filtered.length + " wallpapers · arrows + Enter to select"; color: Colors.textOnSurfaceVariant }
            PixelButton { text: "Refresh collection"; onClicked: WallpaperBackend.refresh() }
        }
        ColumnLayout {
            Layout.fillWidth: true; Layout.preferredWidth: 300; Layout.alignment: Qt.AlignTop; spacing: 10
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 160; color: Colors.background
                Image { anchors.fill: parent; source: Settings.fileUrl(root.selectedPath); asynchronous: true; sourceSize.width: 640; fillMode: Image.PreserveAspectFit }
                PixelText { anchors.centerIn: parent; visible: !root.selectedPath; text: "Select a wallpaper" }
            }
            PixelText { Layout.fillWidth: true; text: root.selectedPath.split("/").pop() || "Nothing selected" }
            RowLayout {
                Rectangle { Layout.preferredWidth: 24; Layout.preferredHeight: 24; color: WallpaperBackend.previewColors.accent || Colors.accent; border.color: Colors.outlineVariant }
                PixelText { text: WallpaperBackend.previewBusy ? "Generating preview…" : "One seed · " + (WallpaperBackend.previewColors._meta?.seed || "—"); Layout.fillWidth: true }
            }
            Flow {
                Layout.fillWidth: true; spacing: 6
                Repeater {
                    model: ["wallpaper", "black", "neutral", "tonal", "expressive", "paper", "mono"]
                    PixelButton { required property string modelData; text: modelData; checked: root.recipe === modelData; primary: checked; onClicked: root.recipe = modelData }
                }
            }
            PixelText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Colors.textOnSurfaceVariant; text: root.recipe === "black" ? "True-black surfaces; wallpaper-colored highlights." : root.recipe === "wallpaper" ? "Wallpaper hue colors the rail, frame, panels and icons." : "A quieter variation of this wallpaper's palette." }
            PixelText { text: "Accent tone · " + Math.round(root.tone); color: Colors.textOnSurfaceVariant }
            PixelSlider { Layout.fillWidth: true; from: -15; to: 15; stepSize: 1; value: root.tone; onMoved: root.tone = value }
            PixelText { text: "Color intensity · " + Math.round(root.saturation * 100) + "%"; color: Colors.textOnSurfaceVariant }
            PixelSlider { Layout.fillWidth: true; from: 0; to: 1.6; stepSize: .05; value: root.saturation; onMoved: root.saturation = value }
            Flow {
                Layout.fillWidth: true; spacing: 6
                Repeater { model: ["representative", "dominant", "colorful"]; PixelButton { required property string modelData; text: modelData; checked: root.sourcePreference === modelData; onClicked: root.sourcePreference = modelData } }
            }
            Rectangle {
                Layout.fillWidth: true; implicitHeight: 46
                color: WallpaperBackend.previewColors.background || Colors.background
                border.color: WallpaperBackend.previewColors.outline_variant || Colors.outlineVariant
                PixelText { anchors.centerIn: parent; text: "Aa  /  live palette preview"; color: WallpaperBackend.previewColors.accent || Colors.accent }
            }
            PixelButton {
                Layout.fillWidth: true; primary: true; enabled: !!root.selectedPath && !WallpaperBackend.applying && !WallpaperBackend.tryingColors
                text: Settings.previewMode ? (WallpaperBackend.tryingColors ? "Trying colors…" : "Try colors on this preview") : WallpaperBackend.applying ? "Applying…" : "Apply wallpaper & palette"
                onClicked: Settings.previewMode ? WallpaperBackend.tryColors(root.selectedPath, root.recipe, root.tone, root.saturation, root.sourcePreference, Settings.contrast) : WallpaperBackend.apply(root.selectedPath, root.recipe, root.tone, root.saturation, root.sourcePreference, Settings.contrast)
            }
            PixelButton {
                Layout.fillWidth: true
                text: WallpaperBackend.syncingApps ? "Syncing apps…" : root.confirmAppSync ? "Confirm live app recoloring" : "Sync live app colors…"
                enabled: !!root.selectedPath && !WallpaperBackend.syncingApps && !WallpaperBackend.applying && !WallpaperBackend.tryingColors
                onClicked: { if (root.confirmAppSync) { WallpaperBackend.syncLiveApps(root.selectedPath); root.confirmAppSync = false; } else root.confirmAppSync = true; }
            }
            PixelText { visible: root.confirmAppSync; Layout.fillWidth: true; text: "This writes your LIVE Wallust templates and recolors Firefox / terminals, even in preview. It does not change the wallpaper."; wrapMode: Text.Wrap; elide: Text.ElideNone; color: Colors.warning }
            PixelButton { visible: root.confirmAppSync; text: "Cancel app sync"; onClicked: root.confirmAppSync = false }
            PixelText { visible: !!WallpaperBackend.appSyncMessage; Layout.fillWidth: true; text: WallpaperBackend.appSyncMessage; wrapMode: Text.Wrap; elide: Text.ElideNone; color: Colors.textOnSurfaceVariant }
            PixelButton { Layout.fillWidth: true; text: root.confirmTrash ? "Confirm move to Trash" : "Move selected to Trash…"; danger: root.confirmTrash; enabled: !!root.selectedPath && !WallpaperBackend.applying; onClicked: { if (root.confirmTrash) { WallpaperBackend.trash(root.selectedPath); root.selectedPath = ""; } else root.confirmTrash = true; } }
            PixelButton { visible: root.confirmTrash; text: "Cancel"; onClicked: root.confirmTrash = false }
        }
    }
    PixelText { Layout.fillWidth: true; visible: text.length > 0; text: WallpaperBackend.lastError; color: Colors.error; wrapMode: Text.Wrap; elide: Text.ElideNone }
}
