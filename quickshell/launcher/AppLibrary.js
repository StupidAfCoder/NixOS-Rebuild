.pragma library
function filter(entries, query, category) {
    var q = query.trim().toLowerCase();
    return entries.filter(function(e) {
        if (!e || e.noDisplay || !e.name) return false;
        var categories = typeof e.categories === "string" ? e.categories.split(";") : Array.from(e.categories || []);
        var matches = category === "All" || (category === "Games" ? categories.indexOf("Game") >= 0
            : category === "Create" ? ["Development", "Graphics", "AudioVideo"].some(function(c) { return categories.indexOf(c) >= 0; })
            : !!e.shellAction || ["Utility", "System", "Settings"].some(function(c) { return categories.indexOf(c) >= 0; }));
        return matches && (!q || (e.name + " " + (e.genericName || "") + " " + (e.comment || "")).toLowerCase().indexOf(q) >= 0);
    }).sort(function(a, b) {
        return Number(a.name.toLowerCase().indexOf(q) !== 0) - Number(b.name.toLowerCase().indexOf(q) !== 0) || a.name.localeCompare(b.name);
    });
}
function move(index, delta, count) { return count ? Math.max(0, Math.min(count - 1, index + delta)) : -1; }

// Names are presentation, not identity: different desktop entries can share one.
function identity(entry) {
    if (!entry) return "";
    return entry.shellAction ? "shell:" + entry.shellAction : entry.id ? "desktop:" + entry.id : "name:" + entry.name;
}
function indexFor(entries, selectedId) {
    if (!entries.length) return -1;
    var index = entries.findIndex(function(entry) { return identity(entry) === selectedId; });
    return index < 0 ? 0 : index;
}
