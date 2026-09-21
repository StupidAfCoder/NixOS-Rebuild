pragma Singleton
import QtQuick
import Quickshell.Io
import "../common"
import "../bar"
import "UsageMath.js" as MathUtils

Item {
    id: root
    property var days: ({})
    property string updated: ""
    property string error: ""
    property bool sampleData: false
    property string audioStatus: "Collector has not reported yet."
    function key(date) { return MathUtils.key(date); }
    function total(day) { return MathUtils.total(days, day); }
    function duration(seconds) { return MathUtils.duration(seconds); }
    function hasDay(day) { return Object.prototype.hasOwnProperty.call(days, day); }
    function appSeries(app, end, count) { return MathUtils.appSeries(days, app, end, count); }
    function series(end, count) { return MathUtils.series(days, end, count); }
    function ranking(keys, descending) { return MathUtils.ranking(days, keys, descending); }
    function level(seconds) { return MathUtils.heatLevel(seconds, Settings.dailyGoalMinutes); }
    function heatColor(level) {
        // One accent, five intensities; works with neutral, saturated and light recipes.
        return Colors.mix(Colors.surfaceContainerHigh, Colors.accent, [0, .18, .38, .65, 1][level]);
    }
    function heatText(level) {
        var bg = heatColor(level);
        return Colors.contrastRatio(Colors.textOnBackground, bg) >= 4.5 ? Colors.textOnBackground : (Colors.contrastRatio("#000000", bg) > Colors.contrastRatio("#ffffff", bg) ? "#000000" : "#ffffff");
    }
    FileView {
        path: Settings.stateDir + "/usage.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const data = JSON.parse(text());
                root.days = MathUtils.sanitizeDays(data.days);
                root.updated = typeof data.updated === "string" ? data.updated : "";
                root.sampleData = data.sampleData === true;
                root.error = "";
            } catch(e) { root.error = "History could not be read. Keeping the last valid view."; }
        }
    }
    FileView {
        path: Settings.stateDir + "/status.json"; watchChanges: true
        onFileChanged: reload()
        onLoaded: { try { root.audioStatus = JSON.parse(text()).audio || ""; } catch(e) {} }
    }
}
