import QtQuick
import QtQuick.Layouts
import "../bar"
import "../common"

Sheet {
    id: root
    property int topOffset: 0
    shown: SysStatsPanel.shown
    title: "System"
    subtitle: "Live readings · unavailable sensors stay blank"
    preferredWidth: 440; preferredHeight: 360
    onDismiss: SysStatsPanel.hide()
    GridLayout {
        Layout.fillWidth: true; columns: root.width > 360 ? 2 : 1; columnSpacing: 12; rowSpacing: 12
        Repeater {
            model: [
                {name: "CPU", value: SysStatsBackend.cpuPct + "%", detail: "Processor usage"},
                {name: "Memory", value: SysStatsBackend.ramUsedGb.toFixed(1) + "G", detail: "of " + SysStatsBackend.ramTotalGb.toFixed(1) + " GiB"},
                {name: "Temperature", value: SysStatsBackend.cpuTemp >= 0 ? SysStatsBackend.cpuTemp + "°" : "—", detail: "CPU · Celsius"},
                {name: "Graphics", value: SysStatsBackend.gpuPct >= 0 ? SysStatsBackend.gpuPct + "%" : "—", detail: SysStatsBackend.gpuTemp >= 0 ? SysStatsBackend.gpuTemp + "°C" : "No GPU sensor"}
            ]
            Rectangle {
                required property var modelData
                Layout.fillWidth: true; implicitHeight: 102; color: Colors.surfaceContainer
                ColumnLayout { anchors.fill: parent; anchors.margins: 14
                    PixelText { text: modelData.name; color: Colors.textOnSurfaceVariant }
                    PixelText { text: modelData.value; font.pixelSize: 26; color: Colors.accent }
                    PixelText { text: modelData.detail; Layout.fillWidth: true; color: Colors.textOnSurfaceVariant }
                }
            }
        }
    }
}
