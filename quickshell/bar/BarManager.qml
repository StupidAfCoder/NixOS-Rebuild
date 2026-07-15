import Quickshell
import Quickshell.Wayland
import QtQuick
import "."

Scope {
    id: manager

    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: barWindow
                required property var modelData
                screen: barWindow.modelData

                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "quickshell:bar"

                anchors { top: true; bottom: true; left: true }
                implicitWidth: 52
                color: "transparent"

                Bar {
                    anchors.fill: parent
                }
            }
        }
    }
}