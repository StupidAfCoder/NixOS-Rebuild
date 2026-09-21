pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../common"
import "../bar"
import "../settings"

Sheet {
    id: root
    shown: WellbeingPanel.shown
    title: "Your day"
    subtitle: Usage.sampleData ? "Sample history · preview only" : Settings.trackingEnabled ? "Focused time, collected locally." : "History paused · Settings / Data"
    centered: true
    preferredWidth: 760
    preferredHeight: 820
    onDismiss: WellbeingPanel.hide()
    property date today: new Date()
    property date month: new Date(today.getFullYear(), today.getMonth(), 1, 12)
    property string selectedDay: Usage.key(today)
    property string graphEnd: Usage.key(today)
    property int period: 14
    property string appScope: "day"
    property bool descending: true
    readonly property int firstWeekday: (month.getDay() + 6) % 7
    readonly property int daysInMonth: new Date(month.getFullYear(), month.getMonth() + 1, 0).getDate()
    readonly property var series: Usage.series(graphEnd, period)
    readonly property real rangeTotal: series.reduce((sum, d) => sum + d.seconds, 0)
    readonly property int recordedDays: series.filter(d => d.recorded).length
    readonly property real chartMaximum: Math.max(3600, Math.ceil(Math.max.apply(null, series.map(d => d.seconds).concat([0])) / 3600) * 3600)
    readonly property var apps: Usage.ranking(appScope === "day" ? [selectedDay] : series.map(d => d.day), descending)
    readonly property real largestApp: Math.max.apply(null, apps.map(a => a.seconds).concat([1]))
    function selectDay(day) {
        selectedDay = day;
        const parts = day.split("-").map(Number);
        month = new Date(parts[0], parts[1] - 1, 1, 12);
        if (!series.some(d => d.day === day)) graphEnd = day;
    }
    function goToday() {
        today = new Date();
        month = new Date(today.getFullYear(), today.getMonth(), 1, 12);
        selectedDay = Usage.key(today); graphEnd = selectedDay;
    }
    function moveMonth(delta) { month = new Date(month.getFullYear(), month.getMonth() + delta, 1, 12); }
    onShownChanged: if (shown) today = new Date()
    Timer { interval: 60000; repeat: true; running: root.shown; onTriggered: root.today = new Date() }

    RowLayout {
        Layout.fillWidth: true; spacing: 12
        ColumnLayout {
            Layout.fillWidth: true; spacing: 4
            PixelText { text: Usage.hasDay(root.selectedDay) ? Usage.duration(Usage.total(root.selectedDay)) : "No data"; font.pixelSize: 32; font.family: "Pixel Operator" }
            PixelText { text: root.selectedDay + " / selected day"; color: Colors.textOnSurfaceVariant; Layout.fillWidth: true }
        }
        PixelButton { text: "Today"; onClicked: root.goToday() }
        PixelButton { text: "Settings"; onClicked: { WellbeingPanel.hide(); SettingsPanel.toggle(); } }
    }

    PixelGroup {
        Layout.fillWidth: true; title: "Time in view"; detail: Usage.duration(root.rangeTotal); iconName: "chart.svg"
        Flow {
            Layout.fillWidth: true; implicitHeight: childrenRect.height; spacing: 6
            Repeater { model: [7, 14, 30]; PixelButton { required property int modelData; text: modelData + " days"; checked: root.period === modelData; onClicked: root.period = modelData } }
        }
        PixelText {
            Layout.fillWidth: true; color: Colors.textOnSurfaceVariant; wrapMode: Text.Wrap; elide: Text.ElideNone
            text: root.recordedDays ? root.recordedDays + " recorded days · average " + Usage.duration(root.rangeTotal / root.recordedDays) + " per recorded day" : "No recorded days in this range. Blank dates are not counted as zero-use days."
        }
        RowLayout {
            Layout.fillWidth: true; spacing: 10
            ColumnLayout {
                Layout.preferredHeight: 152; Layout.preferredWidth: 38
                PixelText { text: Usage.duration(root.chartMaximum); color: Colors.textOnSurfaceVariant; font.pixelSize: 12 }
                Item { Layout.fillHeight: true }
                PixelText { text: "0"; color: Colors.textOnSurfaceVariant; font.pixelSize: 12 }
            }
            Item {
                Layout.fillWidth: true; Layout.preferredHeight: 152
                Repeater {
                    model: 3
                    Rectangle { required property int index; width: parent.width; height: 1; y: index * (parent.height - 1) / 2; color: Colors.outlineVariant; opacity: .6 }
                }
                Row {
                    id: chartRow
                    anchors.fill: parent; spacing: root.period > 14 ? 3 : 6
                    Repeater {
                        model: root.series
                        Item {
                            id: bar
                            required property var modelData
                            width: Math.max(1, (chartRow.width - (root.period - 1) * chartRow.spacing) / root.period)
                            height: chartRow.height
                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: bar.modelData.recorded ? Math.max(2, (parent.height - 3) * bar.modelData.seconds / root.chartMaximum) : 2
                                color: bar.modelData.recorded ? Usage.heatColor(Usage.level(bar.modelData.seconds)) : Colors.outlineVariant
                                border.width: root.selectedDay === bar.modelData.day ? 1 : 0
                                border.color: Colors.textOnBackground
                                Behavior on height { NumberAnimation { duration: Settings.motionMs; easing.type: Easing.OutCubic } }
                            }
                            MouseArea { id: barMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.selectDay(bar.modelData.day) }
                            activeFocusOnTab: true
                            Keys.onReturnPressed: root.selectDay(modelData.day)
                            Rectangle { anchors.fill: parent; color: "transparent"; visible: bar.activeFocus; border.color: Colors.accent; border.width: 2 }
                            ToolTip.visible: barMouse.containsMouse || bar.activeFocus
                            ToolTip.text: modelData.day + " · " + (modelData.recorded ? Usage.duration(modelData.seconds) : "No data")
                            Accessible.role: Accessible.Button
                            Accessible.name: ToolTip.text
                        }
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            PixelText { text: root.series.length ? root.series[0].day : ""; color: Colors.textOnSurfaceVariant; Layout.fillWidth: true }
            PixelText { text: root.graphEnd; color: Colors.textOnSurfaceVariant }
        }
        PixelText { text: "Bar height = focused time. Select a bar for that day's apps."; Layout.fillWidth: true; color: Colors.textOnSurfaceVariant; wrapMode: Text.Wrap }
    }

    PixelGroup {
        Layout.fillWidth: true; title: "Daily rhythm"; iconName: "calendar.svg"
        RowLayout {
            Layout.fillWidth: true
            PixelButton { text: "<"; Accessible.name: "Previous month"; onClicked: root.moveMonth(-1) }
            PixelText { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: Qt.formatDate(root.month, "MMMM yyyy") }
            PixelButton { text: ">"; Accessible.name: "Next month"; onClicked: root.moveMonth(1) }
        }
        GridLayout {
            Layout.fillWidth: true; columns: 7; rowSpacing: 6; columnSpacing: 6
            Repeater { model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]; PixelText { required property string modelData; text: modelData; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; color: Colors.textOnSurfaceVariant } }
            Repeater {
                model: Math.ceil((root.firstWeekday + root.daysInMonth) / 7) * 7
                Button {
                    id: cell
                    required property int index
                    readonly property int day: index - root.firstWeekday + 1
                    readonly property bool validDay: day > 0 && day <= root.daysInMonth
                    readonly property string dayKey: Usage.key(new Date(root.month.getFullYear(), root.month.getMonth(), day, 12))
                    readonly property bool recorded: validDay && Usage.hasDay(dayKey)
                    readonly property int level: recorded ? Usage.level(Usage.total(dayKey)) : 0
                    Layout.fillWidth: true; implicitWidth: 28; implicitHeight: 38
                    enabled: validDay && dayKey <= Usage.key(root.today)
                    hoverEnabled: true
                    Accessible.name: dayKey + " · " + (recorded ? Usage.duration(Usage.total(dayKey)) : "No data")
                    contentItem: PixelText { text: cell.validDay ? String(cell.day) : ""; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; color: cell.recorded ? Usage.heatText(cell.level) : Colors.textOnSurfaceVariant; opacity: cell.enabled ? 1 : .45 }
                    background: Rectangle {
                        visible: cell.validDay
                        color: cell.recorded ? Usage.heatColor(cell.level) : Colors.surface
                        border.color: cell.activeFocus || root.selectedDay === cell.dayKey ? Colors.textOnBackground : cell.hovered ? Colors.accent : Colors.outlineVariant
                        border.width: cell.activeFocus || root.selectedDay === cell.dayKey ? 2 : 1
                        Rectangle { visible: cell.dayKey === Usage.key(root.today); anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; anchors.bottomMargin: 4; width: 6; height: 2; color: cell.recorded ? Usage.heatText(cell.level) : Colors.accent }
                    }
                    onClicked: root.selectDay(dayKey)
                    ToolTip.visible: hovered || activeFocus
                    ToolTip.text: Accessible.name
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true; spacing: 6
            PixelText { text: "Less"; color: Colors.textOnSurfaceVariant }
            Repeater { model: 5; Rectangle { required property int index; implicitWidth: 18; implicitHeight: 14; color: Usage.heatColor(index); border.color: Colors.outlineVariant } }
            PixelText { text: "More"; color: Colors.textOnSurfaceVariant }
            Item { Layout.fillWidth: true }
            Rectangle { implicitWidth: 14; implicitHeight: 14; color: Colors.surface; border.color: Colors.outlineVariant }
            PixelText { text: "No data"; color: Colors.textOnSurfaceVariant }
        }
        PixelText {
            Layout.fillWidth: true; wrapMode: Text.Wrap; elide: Text.ElideNone; color: Colors.textOnSurfaceVariant
            text: "Intensity: 0 · ≤" + Usage.duration(Settings.dailyGoalMinutes * 15) + " · ≤" + Usage.duration(Settings.dailyGoalMinutes * 30) + " · ≤" + Usage.duration(Settings.dailyGoalMinutes * 60) + " · above goal. Colors use the same thresholds across every month."
        }
    }

    PixelGroup {
        Layout.fillWidth: true; title: "Where time went"; iconName: "app-windows.svg"
        Flow {
            Layout.fillWidth: true; implicitHeight: childrenRect.height; spacing: 6
            PixelButton { text: "Selected day"; checked: root.appScope === "day"; onClicked: root.appScope = "day" }
            PixelButton { text: root.period + "-day range"; checked: root.appScope === "range"; onClicked: root.appScope = "range" }
            PixelButton { text: root.descending ? "Most used first" : "Least used first"; onClicked: root.descending = !root.descending }
        }
        PixelText { text: root.appScope === "day" ? root.selectedDay : "Range ending " + root.graphEnd; color: Colors.textOnSurfaceVariant }
        Repeater {
            model: root.apps
            ColumnLayout {
                required property var modelData
                Layout.fillWidth: true; spacing: 8
                RowLayout {
                    Layout.fillWidth: true
                    PixelText { text: modelData.app; Layout.fillWidth: true }
                    PixelText { text: Usage.duration(modelData.seconds) + " · " + Math.round(modelData.share * 100) + "%"; color: Colors.textOnSurfaceVariant }
                }
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 8; color: Colors.surfaceContainerHigh
                    Rectangle { height: parent.height; width: parent.width * modelData.seconds / root.largestApp; color: Colors.accent; Behavior on width { NumberAnimation { duration: Settings.motionMs } } }
                }
            }
        }
        PixelText { visible: root.apps.length === 0; text: "No recorded app activity for this selection. Enable history in Settings / Data to start; past activity cannot be reconstructed."; Layout.fillWidth: true; wrapMode: Text.Wrap; elide: Text.ElideNone; color: Colors.textOnSurfaceVariant }
        PixelText { visible: root.apps.length > 0; text: "Bars are relative to the most-used app; percentages are shares of the selected total."; Layout.fillWidth: true; wrapMode: Text.Wrap; elide: Text.ElideNone; color: Colors.textOnSurfaceVariant }
    }
    PixelText { text: Usage.error || (Usage.updated ? "Saved " + Usage.updated.substring(0,19).replace("T", " ") : "Collector needs the user service installed."); Layout.fillWidth: true; color: Usage.error ? Colors.error : Colors.textOnSurfaceVariant; wrapMode: Text.Wrap }
}
