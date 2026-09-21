pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Hyprland
import "../common"
import "../bar"
import "WorkspaceState.js" as State

Sheet {
    id: root
    title: "Workspaces"
    shown: WorkspacePanel.shown
    preferredWidth: 470; preferredHeight: 730
    initialFocusItem: board
    property int selectedId: Hyprland.focusedWorkspace?.id ? Hyprland.focusedWorkspace.id : 1
    property string movingAddress: ""
    property string previewAddress: ""
    readonly property var previewWindow: windows.find(w => w.address === previewAddress) || windows[0] || null
    readonly property var workspaceIds: State.ids(Hyprland.workspaces.values, Settings.workspaceCount)
    readonly property var selectedWorkspace: Hyprland.workspaces.values.find(w => w.id === selectedId)
    readonly property var windows: selectedWorkspace?.toplevels.values || []
    function select(id) {
        selectedId = id;
        if (movingAddress) {
            // A closed window cannot accidentally turn into a move of the focused one.
            const alive = Hyprland.toplevels.values.some(w => State.address(w.address) === State.address(movingAddress));
            const command = alive && !Settings.previewMode ? State.moveWindow(movingAddress, id, Hyprland.workspaces.values) : "";
            movingAddress = "";
            if (command) { Hyprland.dispatch(command); Hyprland.refreshToplevels(); }
        }
    }
    function cancel() { if (movingAddress) movingAddress = ""; else WorkspacePanel.hide(); }
    onDismiss: cancel()
    onShownChanged: {
        movingAddress = ""; previewAddress = "";
        if (shown) { selectedId = Hyprland.focusedWorkspace?.id ? Hyprland.focusedWorkspace.id : 1; Hyprland.refreshToplevels(); }
    }
    Timer { interval: 2000; repeat: true; running: root.shown; onTriggered: Hyprland.refreshToplevels() }
    RowLayout {
        Layout.fillWidth: true
        PixelText { Layout.fillWidth: true; text: root.movingAddress ? "Move window to…" : Hyprland.workspaces.values.length + " open"; color: root.movingAddress ? Colors.accent : Colors.textOnSurfaceVariant }
        PixelButton { visible: !!root.movingAddress; text: "Cancel"; onClicked: root.movingAddress = "" }
        PixelButton {
            text: "+ New"
            onClicked: {
                const id = State.nextId(root.workspaceIds);
                if (root.movingAddress) root.select(id); else WorkspacePanel.focusWorkspace(id);
            }
        }
    }
    GridView {
        id: board
        Layout.fillWidth: true; Layout.preferredHeight: Math.min(248, Math.ceil(count / columns) * cellHeight)
        readonly property int columns: Math.max(1, Math.floor(width / 94))
        cellWidth: Math.floor((width - 10) / columns); cellHeight: 76
        clip: true; boundsBehavior: Flickable.StopAtBounds
        model: root.workspaceIds
        currentIndex: Math.max(0, root.workspaceIds.indexOf(root.selectedId))
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; width: 8 }
        function navigate(delta) {
            const index = Math.max(0, Math.min(count - 1, root.workspaceIds.indexOf(root.selectedId) + delta));
            root.selectedId = root.workspaceIds[index];
            positionViewAtIndex(index, GridView.Contain);
        }
        Keys.onLeftPressed: navigate(-1)
        Keys.onRightPressed: navigate(1)
        Keys.onUpPressed: navigate(-columns)
        Keys.onDownPressed: navigate(columns)
        Keys.onReturnPressed: { if (root.movingAddress) root.select(root.selectedId); else WorkspacePanel.focusWorkspace(root.selectedId); }
        Keys.onEnterPressed: { if (root.movingAddress) root.select(root.selectedId); else WorkspacePanel.focusWorkspace(root.selectedId); }
        delegate: PixelButton {
            id: tile
            required property int modelData
            readonly property var workspace: Hyprland.workspaces.values.find(w => w.id === modelData)
            width: board.cellWidth - 6; height: board.cellHeight - 6; padding: 8
            checked: root.selectedId === modelData
            Accessible.name: "Workspace " + (workspace?.name || modelData) + ", " + (workspace?.toplevels.values.length || 0) + " windows"
            onClicked: { root.select(modelData); board.forceActiveFocus(); }
            contentItem: Column {
                spacing: 5
                WorkspaceMark { anchors.horizontalCenter: parent.horizontalCenter; active: Hyprland.focusedWorkspace?.id === tile.modelData; occupied: (tile.workspace?.toplevels.values.length || 0) > 0 }
                PixelText { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: tile.modelData < 0 ? tile.workspace?.name || "Space" : String(tile.modelData); color: Colors.accent }
                PixelText { width: parent.width; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 11; text: tile.workspace?.monitor?.name || "Empty"; color: Colors.textOnSurfaceVariant }
            }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        PixelText { Layout.fillWidth: true; text: root.selectedWorkspace?.name && root.selectedWorkspace.name !== String(root.selectedId) ? root.selectedWorkspace.name : "Workspace " + root.selectedId }
        PixelButton { text: "Open"; primary: true; enabled: !root.movingAddress; onClicked: WorkspacePanel.focusWorkspace(root.selectedId) }
    }
    Rectangle {
        visible: Settings.workspacePreviews && root.windows.length > 0
        Layout.fillWidth: true; Layout.preferredHeight: 144
        color: Colors.background; border.color: Colors.outlineVariant
        clip: true
        Loader {
            id: previewLoader
            anchors.fill: parent; anchors.margins: 2
            active: root.shown && Settings.workspacePreviews && !!root.previewWindow?.wayland
            source: "WindowCapture.qml"
            onLoaded: item.captureSource = Qt.binding(function() { return root.previewWindow?.wayland || null; })
        }
        Column {
            anchors.centerIn: parent; spacing: 8
            visible: !previewLoader.item?.hasContent
            ColoredIcon { anchors.horizontalCenter: parent.horizontalCenter; width: 28; height: 28; iconName: AppIdentity.fallback(root.previewWindow?.lastIpcObject?.class || "") || "app-windows.svg" }
            PixelText { text: "Preview unavailable"; color: Colors.textOnSurfaceVariant }
        }
    }
    PixelText { visible: !root.windows.length; text: "No windows"; color: Colors.textOnSurfaceVariant }
    Repeater {
        model: root.windows
        RowLayout {
            id: windowRow
            required property var modelData
            readonly property string appClass: modelData.lastIpcObject?.class || ""
            Layout.fillWidth: true
            MenuRow {
                Layout.fillWidth: true
                label: AppIdentity.name(windowRow.appClass) || "Window"
                detail: windowRow.modelData.title || ""
                iconName: AppIdentity.fallback(windowRow.appClass)
                iconSource: AppIdentity.icon(windowRow.appClass)
                onHoveredChanged: if (hovered) root.previewAddress = windowRow.modelData.address
                onActiveFocusChanged: if (activeFocus) root.previewAddress = windowRow.modelData.address
                onClicked: WorkspacePanel.focusWindow(windowRow.modelData.address)
            }
            PixelButton {
                text: "Move…"; enabled: !Settings.previewMode
                checked: State.address(root.movingAddress) === State.address(windowRow.modelData.address)
                Accessible.name: "Move " + (AppIdentity.name(windowRow.appClass) || "window") + " to another workspace"
                onClicked: { root.movingAddress = windowRow.modelData.address; root.resetScroll(); board.forceActiveFocus(); }
            }
        }
    }
    PixelText { visible: Settings.previewMode; Layout.fillWidth: true; text: "Preview: window moves are disabled."; color: Colors.textOnSurfaceVariant }
}
