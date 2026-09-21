pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.folderlistmodel
import "../bar"
import "CollectionState.js" as CollectionState

ColumnLayout {
    id: root
    property bool directoryOnly: false
    property var filters: ["*"]
    property alias folder: files.folder
    property string selectedPath: ""
    property bool hiddenFiles: false
    signal chosen(string path)
    signal cancelled()
    function localPath(url) { return decodeURIComponent(String(url).replace(/^file:\/\//, "")); }
    function start(path, directories, patterns) {
        directoryOnly = directories; filters = patterns; selectedPath = "";
        const initial = directories ? path : CollectionState.parentPath(path, Settings.home);
        folder = Settings.fileUrl(initial || Settings.home);
        Qt.callLater(function() { location.text = root.localPath(root.folder); location.forceActiveFocus(); });
    }
    function activateIndex(index) {
        if (files.status !== FolderListModel.Ready || index < 0 || index >= files.count) return;
        const path = files.get(index, "filePath");
        if (files.isFolder(index)) folder = Settings.fileUrl(path);
        else selectedPath = path;
    }
    function verifySelection() {
        if (!selectedPath) return;
        for (let i = 0; i < files.count; ++i) if (files.get(i, "filePath") === selectedPath) return;
        selectedPath = "";
    }
    function move(step) {
        list.currentIndex = CollectionState.boundedIndex(files.count, list.currentIndex + step);
        if (list.currentIndex >= 0) list.positionViewAtIndex(list.currentIndex, ListView.Contain);
    }
    onFiltersChanged: selectedPath = ""
    onHiddenFilesChanged: selectedPath = ""
    spacing: 10
    FolderListModel {
        id: files
        folder: Settings.fileUrl(Settings.home)
        showDirs: true; showFiles: !root.directoryOnly
        showDotAndDotDot: false; showHidden: root.hiddenFiles
        caseSensitive: false; showOnlyReadable: true
        onCountChanged: root.verifySelection()
        showDirsFirst: true; sortField: FolderListModel.Name
        nameFilters: root.filters
        onFolderChanged: {
            root.selectedPath = "";
            if (location) location.text = root.localPath(folder);
            if (list) { list.currentIndex = 0; list.positionViewAtBeginning(); }
        }
        onStatusChanged: if (status !== FolderListModel.Ready) root.selectedPath = ""
    }
    RowLayout {
        Layout.fillWidth: true
        IconButton { iconName: "chevron-up.svg"; hint: "Parent folder"; enabled: root.localPath(root.folder) !== "/"; onClicked: root.folder = files.parentFolder }
        PixelField { id: location; Layout.fillWidth: true; text: root.localPath(root.folder); placeholderText: "Absolute directory path"; onAccepted: { if (text.startsWith("/")) root.folder = Settings.fileUrl(text); text = root.localPath(root.folder); } }
    }
    RowLayout {
        Layout.fillWidth: true
        PixelButton { text: "Home"; onClicked: root.folder = Settings.fileUrl(Settings.home) }
        PixelButton { text: "Pictures"; onClicked: root.folder = Settings.fileUrl(Settings.home + "/Pictures") }
        PixelButton { text: "Hidden"; checked: root.hiddenFiles; onClicked: root.hiddenFiles = !root.hiddenFiles }
    }
    ListView {
        id: list
        Layout.fillWidth: true; Layout.preferredHeight: 280
        model: files; clip: true; spacing: 2
        activeFocusOnTab: true
        Keys.onDownPressed: root.move(1)
        Keys.onUpPressed: root.move(-1)
        Keys.onReturnPressed: root.activateIndex(currentIndex)
        Keys.onEnterPressed: root.activateIndex(currentIndex)
        Keys.onBackPressed: root.folder = files.parentFolder
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Backspace) { root.folder = files.parentFolder; event.accepted = true; }
        }
        ScrollBar.vertical: ScrollBar {}
        delegate: MenuRow {
            required property int index
            required property string fileName
            required property string filePath
            required property bool fileIsDir
            focusPolicy: Qt.NoFocus
            width: list.width; implicitHeight: 40; enabled: files.status === FolderListModel.Ready
            label: fileName; iconName: fileIsDir ? "folder.svg" : "app-windows.svg"
            selected: root.selectedPath === filePath || (list.activeFocus && list.currentIndex === index)
            onClicked: { list.currentIndex = index; root.activateIndex(index); list.forceActiveFocus(); }
        }
        PixelText { anchors.centerIn: parent; width: parent.width; wrapMode: Text.Wrap; horizontalAlignment: Text.AlignHCenter; visible: files.count === 0; text: files.status === FolderListModel.Loading ? "Reading…" : "No matching entries, or folder unavailable."; color: Colors.textOnSurfaceVariant }
    }
    PixelText { Layout.fillWidth: true; text: root.directoryOnly ? root.localPath(root.folder) : root.selectedPath || "Choose a file"; color: Colors.textOnSurfaceVariant }
    RowLayout {
        Layout.fillWidth: true
        PixelButton { text: "Cancel"; onClicked: root.cancelled() }
        Item { Layout.fillWidth: true }
        PixelButton { text: root.directoryOnly ? "Use this folder" : "Select file"; primary: true; enabled: files.status === FolderListModel.Ready && (root.directoryOnly || !!root.selectedPath); onClicked: root.chosen(root.directoryOnly ? root.localPath(root.folder) : root.selectedPath) }
    }
}
