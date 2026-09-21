import QtQuick
import QtQuick.Controls
import Quickshell
import "../common"

FocusScope {
    id: level
    required property var levelData
    required property int levelIndex
    width: Math.min(270, parent.width - Settings.barWidth - 20)
    height: Math.min(list.contentHeight + 16, parent.height - 32)
    x: Math.max(Settings.barWidth + 8, Math.min(levelData.x, parent.width - width - 12))
    y: Math.max(12, Math.min(levelData.y, parent.height - height - 12))
    z: 30 + levelIndex
    Component.onCompleted: forceActiveFocus()
    Connections { target: TrayMenu; function onStackChanged() { if (level.levelIndex === TrayMenu.stack.length - 1) level.forceActiveFocus(); } }
    QsMenuOpener { id: opener; menu: level.levelData.handle }
    function activate(index) {
        const entry = opener.children.values[index];
        if (!entry || entry.isSeparator || !entry.enabled) return;
        if (entry.hasChildren) {
            const nextX = level.x + width + 4 + width <= parent.width ? level.x + width + 4 : level.x - width - 4;
            TrayMenu.openSubmenu(entry, nextX, level.y + index * 36 - list.contentY, levelIndex + 1);
        } else { entry.triggered(); TrayMenu.hide(); }
    }
    Keys.onEscapePressed: TrayMenu.hide()
    Keys.onDownPressed: list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1)
    Keys.onUpPressed: list.currentIndex = Math.max(0, list.currentIndex - 1)
    Keys.onReturnPressed: activate(list.currentIndex)
    Keys.onRightPressed: { const entry = opener.children.values[list.currentIndex]; if (entry && entry.hasChildren) activate(list.currentIndex); }
    Keys.onLeftPressed: { if (levelIndex > 0) TrayMenu.stack = TrayMenu.stack.slice(0, levelIndex); else TrayMenu.hide(); }
    Rectangle { anchors.fill: parent; color: Colors.surfaceContainerLow; border.color: Colors.outlineVariant }
    ListView {
        id: list
        anchors.fill: parent; anchors.margins: 8
        model: opener.children
        clip: true; currentIndex: 0
        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
        ScrollBar.vertical: ScrollBar {}
        delegate: Item {
            required property var modelData
            required property int index
            width: list.width; height: modelData.isSeparator ? 8 : 36
            Rectangle { visible: modelData.isSeparator; width: parent.width; height: 1; anchors.verticalCenter: parent.verticalCenter; color: Colors.outlineVariant }
            PixelButton {
                anchors.fill: parent
                visible: !modelData.isSeparator
                enabled: modelData.enabled
                checked: list.currentIndex === index
                text: (modelData.checkState === Qt.Checked ? "✓ " : "") + modelData.text + (modelData.hasChildren ? "  >" : "")
                onClicked: level.activate(index)
            }
        }
    }
}
