pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../common"

Sheet {
    id: root
    property string invokingScreen: ""
    shown: TrayApps.shown
    title: "Background apps"
    preferredWidth: 340
    preferredHeight: Math.min(520, 112 + TrayApps.items.length * 58)
    onDismiss: TrayApps.hide()
    Repeater {
        model: TrayApps.items
        RowLayout {
            id: row
            required property var modelData
            Layout.fillWidth: true
            function openMenu() {
                if (!modelData.hasMenu) return;
                const pos = mapToItem(null, width, 0);
                TrayMenu.openFor(modelData, pos.x, pos.y, root.invokingScreen);
            }
            MenuRow {
                Layout.fillWidth: true
                label: row.modelData.title || row.modelData.id || "Application"
                iconName: TrayApps.iconFor(row.modelData)
                onClicked: row.modelData.onlyMenu && row.modelData.hasMenu ? row.openMenu() : row.modelData.activate()
                MouseArea { anchors.fill: parent; acceptedButtons: Qt.RightButton; onClicked: row.openMenu() }
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Menu || (event.key === Qt.Key_F10 && (event.modifiers & Qt.ShiftModifier))) { row.openMenu(); event.accepted = true; }
                }
            }
            PixelButton { visible: row.modelData.hasMenu; text: "Menu"; Accessible.name: "Menu for " + (row.modelData.title || row.modelData.id); onClicked: row.openMenu() }
        }
    }
    PixelText { visible: !TrayApps.items.length; text: "No background apps."; color: Colors.textOnSurfaceVariant }
}
