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
    subtitle: Usage.sampleData ? "Sample history" : Settings.trackingEnabled ? "" : "Recording paused"
    centered: true
    preferredWidth: 620
    preferredHeight: 740
    onDismiss: WellbeingPanel.hide()
    property int page: 0
    property date today: new Date()
    property date month: new Date(today.getFullYear(), today.getMonth(), 1, 12)
    property string selectedDay: Usage.key(today)
    property string graphEnd: Usage.key(today)
    property int period: 7
    property bool rangeApps: false
    property bool descending: true
    readonly property var series: Usage.series(graphEnd, period)
    readonly property real periodTotal: series.reduce((n,d) => n + d.seconds, 0)
    readonly property int recordedDays: series.filter(d => d.recorded).length
    readonly property real retainedTotal: Object.keys(Usage.days).reduce((n,day) => n + Usage.total(day), 0)
    readonly property var apps: Usage.ranking(rangeApps ? series.map(d => d.day) : [selectedDay], descending)
    readonly property var dailyApps: Usage.ranking([selectedDay], true)
    readonly property real maximum: Math.max(3600, Math.ceil(Math.max.apply(null, series.map(d => d.seconds).concat([0])) / 3600) * 3600)
    readonly property real largestApp: Math.max.apply(null, apps.map(a => a.seconds).concat([1]))
    readonly property int firstWeekday: (month.getDay() + 6) % 7
    readonly property int daysInMonth: new Date(month.getFullYear(), month.getMonth() + 1, 0).getDate()
    function changePage(next) { page = (next + 3) % 3; resetScroll(); }
    function selectDay(day) {
        selectedDay = day;
        const parts = day.split("-").map(Number);
        month = new Date(parts[0], parts[1] - 1, 1, 12);
        if (!series.some(d => d.day === day)) graphEnd = day;
        rangeApps = false;
        changePage(0);
    }
    function goToday() {
        today = new Date(); selectedDay = Usage.key(today); graphEnd = selectedDay;
        month = new Date(today.getFullYear(), today.getMonth(), 1, 12);
        changePage(0);
    }
    function updateToday() {
        const previous = Usage.key(today);
        today = new Date();
        if (selectedDay === previous) selectedDay = Usage.key(today);
        if (graphEnd === previous) graphEnd = Usage.key(today);
    }
    onShownChanged: if (shown) updateToday()
    Timer { interval: 60000; running: root.shown; repeat: true; onTriggered: root.updateToday() }
    Timer { interval: 60000; repeat: true; running: root.shown; onTriggered: root.today = new Date() }
    RowLayout {
        Layout.fillWidth: true
        Repeater {
            model: ["Day", "History", "Apps"]
            TabButton { required property string modelData; required property int index; text: modelData; selected: root.page === index; onClicked: root.changePage(index) }
        }
        Item { Layout.fillWidth: true }
        IconButton { iconName: "chevron-left.svg"; hint: "Previous page"; onClicked: root.changePage(root.page - 1) }
        IconButton { iconName: "chevron-right.svg"; hint: "Next page"; onClicked: root.changePage(root.page + 1) }
    }
    ColumnLayout {
        visible: root.page === 0; Layout.fillWidth: true; spacing: 22
        PixelText { text: root.selectedDay === Usage.key(root.today) ? "Today" : root.selectedDay; color: Colors.textOnSurfaceVariant }
        PixelText { text: Usage.hasDay(root.selectedDay) ? Usage.duration(Usage.total(root.selectedDay)) : "No history"; font.family: "Pixel Operator"; font.pixelSize: 52; Layout.fillWidth: true }
        PixelText { text: "Focused time"; color: Colors.textOnSurfaceVariant }
        RowLayout {
            Layout.fillWidth: true; spacing: 5
            Repeater {
                model: 16
                Rectangle {
                    required property int index
                    Layout.fillWidth: true; implicitHeight: 6
                    color: Usage.total(root.selectedDay) / (Settings.dailyGoalMinutes * 60) > index / 16 ? Colors.accent : Colors.surfaceContainerHigh
                }
            }
        }
        PixelText { text: "Reference goal  /  " + Usage.duration(Settings.dailyGoalMinutes * 60); color: Colors.textOnSurfaceVariant }
        ColumnLayout {
            Layout.fillWidth: true; spacing: 6
            Repeater {
                model: root.dailyApps.slice(0,3)
                MenuRow {
                    required property var modelData
                    Layout.fillWidth: true
                    label: modelData.app; trailing: Usage.duration(modelData.seconds)
                    onClicked: { root.rangeApps = false; root.changePage(2); }
                }
            }
        }
        PixelText { visible: !root.dailyApps.length; text: Usage.hasDay(root.selectedDay) ? "No focused activity recorded on this day." : "Enable local history in Settings to begin."; wrapMode: Text.Wrap; Layout.fillWidth: true; color: Colors.textOnSurfaceVariant }
        RowLayout {
            Layout.fillWidth: true
            PixelButton { text: "All apps"; visible: root.dailyApps.length > 0; onClicked: { root.rangeApps = false; root.changePage(2); } }
            PixelButton { text: "Today"; visible: root.selectedDay !== Usage.key(root.today); onClicked: root.goToday() }
            Item { Layout.fillWidth: true }
            IconButton { iconName: "settings-2.svg"; hint: "History settings"; onClicked: { WellbeingPanel.hide(); SettingsPanel.toggle(); } }
        }
    }
    ColumnLayout {
        visible: root.page === 1; Layout.fillWidth: true; spacing: 16
        RowLayout {
            Layout.fillWidth: true
            Repeater { model: [7,14,30]; TabButton { required property int modelData; text: modelData + " days"; selected: root.period === modelData; onClicked: root.period = modelData } }
            Item { Layout.fillWidth: true }
            PixelText { text: Usage.duration(root.periodTotal); color: Colors.accent }
        }
        Row {
            id: graph
            Layout.fillWidth: true; Layout.preferredHeight: 100; spacing: root.period > 14 ? 3 : 6
            Repeater {
                model: root.series
                Button {
                    id: bar
                    required property var modelData
                    width: Math.max(1, (graph.width - (root.period - 1) * graph.spacing) / root.period)
                    height: graph.height
                    Accessible.name: modelData.day + ": " + (modelData.recorded ? Usage.duration(modelData.seconds) : "No data")
                    background: Item {
                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: Math.max(2, parent.height * bar.modelData.seconds / root.maximum); color: bar.modelData.recorded ? Usage.heatColor(Usage.level(bar.modelData.seconds)) : Colors.outlineVariant }
                        Rectangle { anchors.fill: parent; color: "transparent"; border.color: Colors.accent; visible: bar.activeFocus }
                    }
                    onClicked: root.selectDay(modelData.day)
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            PixelText { text: root.series.length ? root.series[0].day : ""; Layout.fillWidth: true; color: Colors.textOnSurfaceVariant }
            PixelText { text: "0–" + Usage.duration(root.maximum); color: Colors.textOnSurfaceVariant }
            PixelText { text: root.graphEnd; color: Colors.textOnSurfaceVariant }
        }
        PixelText {
            text: (root.recordedDays ? Usage.duration(root.periodTotal / root.recordedDays) + " / recorded day" : "No recorded days") + "  ·  " + Usage.duration(root.retainedTotal) + " retained total"
            Layout.fillWidth: true; wrapMode: Text.Wrap; color: Colors.textOnSurfaceVariant
        }
        RowLayout {
            Layout.fillWidth: true
            IconButton { iconName: "chevron-left.svg"; hint: "Previous month"; onClicked: root.month = new Date(root.month.getFullYear(), root.month.getMonth()-1,1,12) }
            PixelText { text: Qt.formatDate(root.month,"MMMM yyyy"); Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
            IconButton { iconName: "chevron-right.svg"; hint: "Next month"; onClicked: root.month = new Date(root.month.getFullYear(), root.month.getMonth()+1,1,12) }
        }
        GridLayout {
            Layout.fillWidth: true; columns: 7; columnSpacing: 5; rowSpacing: 5
            Repeater { model: ["M","T","W","T","F","S","S"]; PixelText { required property string modelData; text: modelData; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; color: Colors.textOnSurfaceVariant } }
            Repeater {
                model: Math.ceil((root.firstWeekday + root.daysInMonth) / 7) * 7
                Button {
                    id: cell
                    required property int index
                    readonly property int day: index - root.firstWeekday + 1
                    readonly property bool validDay: day > 0 && day <= root.daysInMonth
                    readonly property string dayKey: Usage.key(new Date(root.month.getFullYear(),root.month.getMonth(),day,12))
                    readonly property bool recorded: validDay && Usage.hasDay(dayKey)
                    readonly property int level: recorded ? Usage.level(Usage.total(dayKey)) : 0
                    Layout.fillWidth: true; implicitWidth: 26; implicitHeight: 32
                    enabled: validDay && dayKey <= Usage.key(root.today)
                    Accessible.name: dayKey + ": " + (recorded ? Usage.duration(Usage.total(dayKey)) : "No data")
                    contentItem: PixelText { text: cell.validDay ? String(cell.day) : ""; color: cell.recorded ? Usage.heatText(cell.level) : Colors.textOnSurfaceVariant; opacity: cell.enabled ? 1 : .4; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle {
                        visible: cell.validDay
                        color: cell.recorded ? Usage.heatColor(cell.level) : "transparent"
                        border.width: cell.activeFocus || root.selectedDay === cell.dayKey ? 1 : 0
                        border.color: Colors.textOnBackground
                        Rectangle { visible: cell.dayKey === Usage.key(root.today); width: 4; height: 2; anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; anchors.bottomMargin: 2; color: cell.recorded ? Usage.heatText(cell.level) : Colors.accent }
                    }
                    onClicked: root.selectDay(dayKey)
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true; spacing: 5
            PixelText { text: "Less"; color: Colors.textOnSurfaceVariant }
            Repeater { model: 5; Rectangle { required property int index; implicitWidth: 14; implicitHeight: 10; color: Usage.heatColor(index) } }
            PixelText { text: "More"; color: Colors.textOnSurfaceVariant }
            Item { Layout.fillWidth: true }
            PixelText { text: "Blank = no data"; color: Colors.textOnSurfaceVariant }
        }
    }
    ColumnLayout {
        visible: root.page === 2; Layout.fillWidth: true; spacing: 18
        Flow {
            Layout.fillWidth: true; spacing: 6
            TabButton { text: "Day"; selected: !root.rangeApps; onClicked: root.rangeApps = false }
            TabButton { text: root.period + " days"; selected: root.rangeApps; onClicked: root.rangeApps = true }
            PixelButton { text: root.descending ? "Most used" : "Least used"; onClicked: root.descending = !root.descending }
        }
        PixelText { text: root.rangeApps ? "Through " + root.graphEnd : root.selectedDay; color: Colors.textOnSurfaceVariant }
        Repeater {
            model: root.apps
            ColumnLayout {
                id: appRow
                required property var modelData
                Layout.fillWidth: true; spacing: 8
                RowLayout {
                    Layout.fillWidth: true
                    PixelText { text: appRow.modelData.app; Layout.fillWidth: true }
                    PixelText { text: Usage.duration(appRow.modelData.seconds) + "  /  " + Math.round(appRow.modelData.share * 100) + "%"; color: Colors.textOnSurfaceVariant }
                }
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 4; color: Colors.surfaceContainerHigh
                    Rectangle { width: parent.width * appRow.modelData.seconds / root.largestApp; height: parent.height; color: Colors.accent }
                }
            }
        }
        PixelText { visible: !root.apps.length; text: "No app activity for this selection."; Layout.fillWidth: true; color: Colors.textOnSurfaceVariant }
    }
    PixelText { visible: !!Usage.error; text: Usage.error; Layout.fillWidth: true; wrapMode: Text.Wrap; color: Colors.error }
}
