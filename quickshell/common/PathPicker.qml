pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.folderlistmodel
import "../bar"

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
        const initial = directories ? path : path.substring(0, path.lastIndexOf("/"));
        folder = Settings.fileUrl(initial || Settings.home);
        Qt.callLater(function() { location.forceActiveFocus(); });
    }
    spacing: 10
    FolderListModel {
        id: files
        folder: Settings.fileUrl(Settings.home)
        showDirs: true; showFiles: !root.directoryOnly
        showDotAndDotDot: false; showHidden: root.hiddenFiles
        showDirsFirst: true; sortField: FolderListModel.Name
        nameFilters: root.filters
        onFolderChanged: { root.selectedPath = ""; if (list) list.positionViewAtBeginning(); }
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
        ScrollBar.vertical: ScrollBar {}
        delegate: MenuRow {
            required property string fileName
            required property string filePath
            required property bool fileIsDir
            width: list.width; implicitHeight: 40
            label: fileName; iconName: fileIsDir ? "folder.svg" : "app-windows.svg"
            selected: root.selectedPath === filePath
            onClicked: { if (fileIsDir) root.folder = Settings.fileUrl(filePath); else root.selectedPath = filePath; }
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
