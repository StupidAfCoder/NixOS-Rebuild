-- Own only shell shortcuts. Never unbind a chord belonging to another action.
local M = { version = 1, handles = {}, previous = nil }
local allowed = { launcher = true, wallpaper = true, quickwallpaper = true,
    workspaces = true, settings = true, wellbeing = true, power = true }
local function enabled(handles, value)
    for _, handle in ipairs(handles) do handle:set_enabled(value) end
end
function M.apply(rows)
    M.previous = nil
    local created = {}
    local ok, err = pcall(function()
        for _, row in ipairs(rows) do
            assert(allowed[row.id] and type(row.chord) == "string", "Invalid shell shortcut")
            local handle = assert(hl.bind(row.chord, hl.dsp.exec_cmd("qs ipc call " .. row.id .. " toggle"),
                { description = "Pixel shell: " .. row.id }), "Shortcut could not be registered")
            table.insert(created, handle)
            handle:set_enabled(false)
        end
    end)
    if not ok then enabled(created, false); error(err) end
    M.previous = M.handles
    enabled(M.handles, false)
    M.handles = created
    enabled(M.handles, true)
end
function M.undo()
    if not M.previous then return end
    enabled(M.handles, false)
    M.handles = M.previous
    M.previous = nil
    enabled(M.handles, true)
end
_G.pixel_shell_keys = M
local directory = debug.getinfo(1, "S").source:sub(2):match("^(.*)/")
local configHome = os.getenv("XDG_CONFIG_HOME")
if not configHome or configHome == "" then configHome = os.getenv("HOME") .. "/.config" end
local config = configHome .. "/pixel-shell/keybindings.lua"
local file = io.open(config, "r")
local loaded = false
if file then
    file:close()
    local chunk = loadfile(config, "t", {})
    if chunk then
        local ok, rows = pcall(chunk)
        if ok and type(rows) == "table" then loaded = pcall(M.apply, rows) end
    end
    if not loaded then print("Pixel shell: invalid saved shortcuts; using defaults") end
end
if not loaded then M.apply(dofile(directory .. "/shell-keybindings-defaults.lua")) end
M.previous = nil
return M
