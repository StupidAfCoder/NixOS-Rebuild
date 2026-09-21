window.moduleCatalog = (function(){


function entries() {
    return [
        {key: "launcher", label: "App launcher", icon: "app-windows.svg", description: "NixOS button at the top of the rail."},
        {key: "workspaces", label: "Workspaces", icon: "app-windows.svg", description: "Pixel indicators and representative app icons."},
        {key: "clock", label: "Clock & calendar", icon: "clock.svg", description: "Time, date and a shortcut to Your day."},
        {key: "wizard", label: "Wallpaper wizard", icon: "brush.svg", description: "Your original mascot, recolored with each wallpaper."},
        {key: "media", label: "Now playing", icon: "music.svg", description: "Music controls; a vertical title when there is room."},
        {key: "audio", label: "Sound & brightness", icon: "volume-2.svg", description: "Volume, mute, output devices and brightness."},
        {key: "system", label: "System readings", icon: "cpu.svg", description: "Processor, memory and available sensors."},
        {key: "battery", label: "Battery & energy", icon: "battery-full.svg", description: "Charge on laptops; power profiles on desktops."},
        {key: "network", label: "Network", icon: "wifi.svg", description: "Wi-Fi and wired connection status."},
        {key: "bluetooth", label: "Bluetooth", icon: "bluetooth.svg", description: "Shown when an adapter is available."},
        {key: "tray", label: "Application tray", icon: "database.svg", description: "Status icons and right-click application menus."},
        {key: "power", label: "Power drawer", icon: "power.svg", description: "Video, lock, sleep and confirmed session actions."}
    ];
}
function defaults() {
    var result = {};
    entries().forEach(function(entry) { result[entry.key] = true; });
    return result;
}

return {entries,defaults};
})();
