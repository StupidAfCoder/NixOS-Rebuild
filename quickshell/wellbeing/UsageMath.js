.pragma library

// Pure calendar/aggregation helpers shared by the UI and Node regression tests.
function key(date) {
    return date.getFullYear() + "-" + String(date.getMonth() + 1).padStart(2, "0") + "-" + String(date.getDate()).padStart(2, "0");
}
function dateFor(value) {
    if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(value)) return null;
    var parts = value.split("-").map(Number);
    // Local noon avoids UTC date shifts and midnight daylight-saving transitions.
    var date = new Date(parts[0], parts[1] - 1, parts[2], 12);
    return key(date) === value ? date : null;
}
function sanitizeDays(input) {
    var result = {};
    if (!input || typeof input !== "object" || Array.isArray(input)) return result;
    Object.keys(input).forEach(function(day) {
        var apps = input[day];
        if (!dateFor(day) || !apps || typeof apps !== "object" || Array.isArray(apps)) return;
        var clean = {};
        Object.keys(apps).forEach(function(app) {
            var value = apps[app];
            if (app && app !== "__proto__" && app !== "constructor" && app !== "prototype" && typeof value === "number" && isFinite(value) && value >= 0 && value <= 86400)
                clean[app] = value;
        });
        result[day] = clean;
    });
    return result;
}
function total(days, day) {
    return Object.values(days[day] || {}).reduce(function(sum, value) { return sum + value; }, 0);
}
function duration(seconds) {
    seconds = Math.max(0, Math.floor(seconds || 0));
    if (seconds > 0 && seconds < 60) return "<1m";
    var minutes = Math.floor(seconds / 60);
    return minutes >= 60 ? Math.floor(minutes / 60) + "h " + minutes % 60 + "m" : minutes + "m";
}
function heatLevel(seconds, goalMinutes) {
    if (seconds <= 0) return 0;
    var ratio = seconds / (Math.max(1, goalMinutes) * 60);
    return ratio <= .25 ? 1 : ratio <= .5 ? 2 : ratio <= 1 ? 3 : 4;
}
function series(days, endKey, count) {
    var end = dateFor(endKey);
    if (!end || [7, 14, 30].indexOf(count) < 0) return [];
    var result = [];
    for (var i = count - 1; i >= 0; i--) {
        var day = new Date(end.getFullYear(), end.getMonth(), end.getDate() - i, 12);
        var name = key(day);
        result.push({day: name, seconds: total(days, name), recorded: Object.prototype.hasOwnProperty.call(days, name)});
    }
    return result;
}
function ranking(days, keys, descending) {
    var apps = Object.create(null);
    keys.forEach(function(day) {
        Object.entries(days[day] || {}).forEach(function(entry) {
            apps[entry[0]] = (apps[entry[0]] || 0) + entry[1];
        });
    });
    var all = Object.values(apps).reduce(function(a, b) { return a + b; }, 0);
    return Object.entries(apps).filter(function(e) { return e[1] > 0; }).map(function(entry) {
        return {app: entry[0], seconds: entry[1], share: all ? entry[1] / all : 0};
    }).sort(function(a, b) { return (descending ? b.seconds - a.seconds : a.seconds - b.seconds) || a.app.localeCompare(b.app); });
}

function appSeries(days, app, end, count) {
    return series(days, end, count).map(function(day) {
        return {day: day.day, recorded: day.recorded, seconds: (days[day.day] || {})[app] || 0};
    });
}
