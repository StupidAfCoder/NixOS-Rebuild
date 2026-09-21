.pragma library

function validId(id) { return typeof id === "number" && isFinite(id) && Math.floor(id) === id && id > 0 && id <= 2147483647; }
function existingId(id) { return typeof id === "number" && isFinite(id) && Math.floor(id) === id && id !== 0 && Math.abs(id) <= 2147483647; }
function isSpecial(workspace) { return !!workspace && (workspace.name === "special" || String(workspace.name).indexOf("special:") === 0); }
function luaString(value) {
    return '"' + String(value).replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/[\x00-\x1f\x7f]/g,
        function(c) { return "\\" + String(c.charCodeAt(0)).padStart(3, "0"); }) + '"';
}
function selector(id, workspaces) {
    if (validId(id)) return String(id);
    const workspace = (workspaces || []).find(w => w.id === id);
    if (!existingId(id) || !workspace || typeof workspace.name !== "string" || !workspace.name) return "";
    return luaString(isSpecial(workspace) ? workspace.name : "name:" + workspace.name);
}
function ids(workspaces, count) {
    var found = [];
    for (var i = 1; i <= count; ++i) found.push(i);
    for (var w of workspaces) if (existingId(w.id) && (validId(w.id) || (typeof w.name === "string" && w.name)) && found.indexOf(w.id) < 0) found.push(w.id);
    return found.sort(function(a, b) { return a > 0 && b <= 0 ? -1 : b > 0 && a <= 0 ? 1 : a - b; });
}
function slots(count, activeId) {
    var result = ids([], count);
    if (existingId(activeId) && (activeId > count || activeId < 0) && result.length) result[result.length - 1] = activeId;
    return result;
}
function nextId(existing) {
    var id = 1;
    while (existing.indexOf(id) >= 0) ++id;
    return id;
}
function address(value) {
    var hex = String(value || "").replace(/^0x/i, "");
    return /^[0-9a-f]{1,16}$/i.test(hex) && /[1-9a-f]/i.test(hex) ? "address:0x" + hex.toLowerCase() : "";
}
function focusWorkspace(id, workspaces) {
    const target = selector(id, workspaces), workspace = (workspaces || []).find(w => w.id === id);
    if (!target) return "";
    return isSpecial(workspace) ? "hl.dsp.workspace.toggle_special(" + luaString(workspace.name.replace(/^special:?/, "")) + ")"
        : "hl.dsp.focus({ workspace = " + target + " })";
}
function focusWindow(value) {
    var target = address(value);
    return target ? 'hl.dsp.focus({ window = "' + target + '" })' : "";
}
function moveWindow(value, id, workspaces) {
    var target = address(value), destination = selector(id, workspaces);
    return target && destination ? 'hl.dsp.window.move({ window = "' + target + '", workspace = ' + destination + ', follow = false })' : "";
}
