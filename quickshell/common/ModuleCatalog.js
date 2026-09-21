.pragma library

function entries() {
    return [
        {key: "launcher", label: "App launcher", icon: "app-windows.svg", description: "Your searchable library, opening from the top or bottom."},
        {key: "workspaces", label: "Workspaces", icon: "app-windows.svg", description: "Pixel indicators and representative app icons."},
        {key: "clock", label: "Clock & calendar", icon: "clock.svg", description: "Time, date and a shortcut to Your day."},
        {key: "wizard", label: "Wallpaper wizard", icon: "brush.svg", description: "Your original mascot, recolored with each wallpaper."},
        {key: "media", label: "Now playing", icon: "music.svg", description: "Music controls; a vertical title when there is room."},
        {key: "audio", label: "Sound & brightness", icon: "volume-2.svg", description: "Volume, mute, output devices and brightness."},
        {key: "system", label: "System readings", icon: "cpu.svg", description: "Processor, memory and available sensors."},
        {key: "battery", label: "Battery & energy", icon: "battery-full.svg", description: "Charge on laptops; power profiles on desktops."},
        {key: "network", label: "Network", icon: "wifi.svg", description: "Wi-Fi and wired connection status."},
        {key: "bluetooth", label: "Bluetooth", icon: "bluetooth.svg", description: "Shown when an adapter is available."},
        {key: "tray", label: "Application tray", icon: "database.svg", description: "Background apps grouped behind one rail control."},
        {key: "settings", label: "Settings button", icon: "settings-2.svg", description: "Optional button. Top-edge reveal, Library and shortcut always work."},
        {key: "power", label: "Power drawer", icon: "power.svg", description: "Video, lock, sleep and confirmed session actions."}
    ];
}
function defaults() {
    var result = {};
    entries().forEach(function(entry) { result[entry.key] = entry.key !== "settings" && entry.key !== "system"; });
    return result;
}

function layoutDefaults() {
    return {top: ["launcher", "workspaces"], middle: ["wizard", "media", "clock"],
            bottom: ["audio", "system", "battery", "network", "bluetooth", "tray", "settings", "power"]};
}
// Defensive when an externally edited file is being read before Python validates it.
function layout(raw) {
    var result = {top: [], middle: [], bottom: []}, seen = {}, defaults = layoutDefaults();
    var known = entries().map(function(e) { return e.key; });
    Object.keys(result).forEach(function(zone) {
        var list = raw && Array.isArray(raw[zone]) ? raw[zone] : [];
        list.forEach(function(key) {
            if (known.indexOf(key) >= 0 && !seen[key]) { result[zone].push(key); seen[key] = true; }
        });
    });
    Object.keys(result).forEach(function(zone) {
        defaults[zone].forEach(function(key) { if (!seen[key]) { result[zone].push(key); seen[key] = true; } });
    });
    return result;
}
function relocate(raw, key, zone, offset) {
    var result = layout(raw);
    if (!result[zone] || entries().every(function(e) { return e.key !== key; })) return result;
    var index = result[zone].indexOf(key);
    if (index >= 0) {
        var next = Math.max(0, Math.min(result[zone].length - 1, index + offset));
        result[zone].splice(index, 1); result[zone].splice(next, 0, key);
    } else {
        Object.keys(result).forEach(function(z) { result[z] = result[z].filter(function(k) { return k !== key; }); });
        result[zone].push(key);
    }
    return result;
}
