pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../common"
import "../bar"

ColumnLayout {
    id: root
    spacing: 14
    PixelGroup {
        title: "Keys"; detail: "Shell shortcuts"; iconName: "settings-2.svg"; Layout.fillWidth: true
        PixelText {
            Layout.fillWidth: true; wrapMode: Text.Wrap; elide: Text.ElideNone
            text: Settings.previewMode ? "Preview edits stay private; they do not install or change live shortcuts." : "Apply updates only shell shortcuts. Window, workspace-switching and application bindings stay untouched."
        }
        PixelText { text: "Shared modifier" }
        PixelField {
            Layout.fillWidth: true; enabled: Keybindings.ready && !Keybindings.running
            text: Keybindings.draft.shared; placeholderText: "ALT, SUPER, CTRL, SHIFT…"
            onTextEdited: Keybindings.changeShared(text)
            Accessible.name: "Shared shortcut modifier"
        }
        PixelText { text: "Use + for combinations. Each action can follow this modifier or use its own full shortcut."; Layout.fillWidth: true; wrapMode: Text.Wrap; elide: Text.ElideNone; color: Colors.textOnSurfaceVariant }
        Repeater {
            model: Keybindings.catalog
            ColumnLayout {
                id: row
                required property var modelData
                readonly property var action: Keybindings.draft.actions[modelData.id] || ({})
                Layout.fillWidth: true; spacing: 5
                RowLayout {
                    Layout.fillWidth: true
                    PixelText { text: row.modelData.label; Layout.fillWidth: true }
                    PixelButton { text: row.action.enabled ? "On" : "Off"; checked: row.action.enabled === true; enabled: !Keybindings.running; Accessible.name: row.modelData.label + " shortcut enabled"; onClicked: Keybindings.changeAction(row.modelData.id, "enabled", !row.action.enabled) }
                }
                RowLayout {
                    Layout.fillWidth: true
                    PixelButton { text: row.action.shared ? "Shared" : "Own"; checked: row.action.shared === true; enabled: !Keybindings.running && row.action.enabled; Accessible.name: row.modelData.label + " follows shared modifier"; onClicked: Keybindings.changeAction(row.modelData.id, "shared", !row.action.shared) }
                    PixelField { Layout.fillWidth: true; enabled: !Keybindings.running && row.action.enabled; text: row.action.key || ""; placeholderText: "CTRL + W / F8 / code:38"; Accessible.name: row.modelData.label + " key"; onTextEdited: Keybindings.changeAction(row.modelData.id, "key", text) }
                }
                PixelText { text: Keybindings.display(row.modelData.id); Layout.fillWidth: true; color: Colors.accent }
            }
        }
        PixelText { text: "Bare keys are allowed in Own mode, but will consume normal typing. Modifier chords or function keys are safer. Live Apply checks for conflicts with existing bindings."; Layout.fillWidth: true; wrapMode: Text.Wrap; elide: Text.ElideNone; color: Colors.textOnSurfaceVariant }
        Flow {
            Layout.fillWidth: true; spacing: 6
            PixelButton { text: Settings.previewMode ? "Save preview" : "Apply"; primary: true; enabled: Keybindings.ready && Keybindings.dirty && !Keybindings.running; onClicked: Keybindings.request("apply") }
            PixelButton { text: "Revert"; enabled: !Keybindings.running; onClicked: Keybindings.request("read") }
            PixelButton { text: "Defaults"; enabled: !Keybindings.running; onClicked: Keybindings.request("defaults") }
        }
        PixelText { text: Keybindings.error || Keybindings.message; visible: text.length > 0; color: Keybindings.error ? Colors.error : Colors.accent; Layout.fillWidth: true; wrapMode: Text.Wrap; elide: Text.ElideNone }
        PixelText { text: "Recovery: open Settings from Library or the top-edge handle. Terminal: qs ipc call settings toggle"; Layout.fillWidth: true; wrapMode: Text.Wrap; elide: Text.ElideNone; color: Colors.textOnSurfaceVariant }
    }
}
