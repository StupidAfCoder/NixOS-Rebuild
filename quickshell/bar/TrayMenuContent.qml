import QtQuick
import "."

Item {
    id: content
    width: TrayMenu.shown ? parent.width : 0
    height: TrayMenu.shown ? parent.height : 0
    visible: TrayMenu.shown
    z: 10

    Repeater {
        model: TrayMenu.stack
        delegate: TrayMenuLevel {
            required property var modelData
            required property int index
            levelData: modelData
            levelIndex: index
        }
    }
}