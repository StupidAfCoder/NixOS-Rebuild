------------------
---- MONITORS ----
------------------
hl.monitor({
    output   = "",
    mode     = "1920x1080@180",
    position = "0x0",
    scale    = 1,
})

---------------------
---- MY PROGRAMS ----
---------------------
local terminal    = "kitty"
local fileManager = "thunar"
local menu        = "fuzzel"
local browser     = "firefox"

-------------------
---- AUTOSTART ----
-------------------
hl.on("hyprland.start", function () 
    -- Force Hyprland's internal renderer
    hl.exec_cmd("hyprctl setcursor MeguminCursor 24")
    
    -- The strictly correct NixOS GTK fix using dconf
    hl.exec_cmd("dconf write /org/gnome/desktop/interface/cursor-theme \"'MeguminCursor'\"")
    hl.exec_cmd("dconf write /org/gnome/desktop/interface/cursor-size 24")

    --Wallpapers!
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("awww img ~/Pictures/Wallpapers/wallhaven-lywpjl_1920x1080.png --transition-type center")

    --Kde authentication for sudo password gui
    hl.exec_cmd("lxqt-policykit-agent")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
hl.env("HYPRCURSOR_THEME", "MeguminCursor")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "MeguminCursor")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")


-----------------------
----- PERMISSIONS -----
-----------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

-- hl.config({
--   ecosystem = {
--     enforce_permissions = true,
--   },
-- })

-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")


-----------------------
---- LOOK AND FEEL ----
-----------------------
hl.config({
    render = {
        direct_scanout = 2, -- 2 means auto (on with content type 'game')
    },
    misc = {
        vrr = 2, -- Controls Adaptive Sync. 2 means fullscreen only
    }
})


hl.config({
    general = {
        gaps_in  = 6,
        gaps_out = 9,

        border_size = 2,

        col = {
            active_border   = { colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = true,

        -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 5,
        rounding_power = 3,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 1.0,
        inactive_opacity = 0.5,

        shadow = {
            enabled      = true,
            range        = 5,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled   = true,
            size      = 8,
            passes    = 3,
            vibrancy  = 0.1696,
        },

        glow = {
            enabled = true,
            range = 5,
            render_power = 3,
        },
    },

    animations = {
        enabled = true,
    },
})

------------------------------------------------
---- FLUID BEZIER ANIMATIONS                ----
------------------------------------------------

-- The Curves (No springs, pure math)
-- fluent_decel: rapid start, buttery smooth deceleration
hl.curve("fluent_decel",   { type = "bezier", points = { {0.1, 1}, {0.0, 1} } })
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })
hl.curve("easeOutExpo",    { type = "bezier", points = { {0.16, 1}, {0.3, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0}, {1, 1} } })
hl.curve("md3_decel",    { type = "bezier", points = { {0.05, 0.7}, {0.1, 1.0} } })
------------------------------------------------
---- THE COMPLETE ANIMATION TREE            ----
------------------------------------------------

-- 1. Global Fallback
hl.animation({ leaf = "global", enabled = true, speed = 4, bezier = "fluent_decel" })

-- 2. Windows (Parent handles all window states unless overridden)
-- Using a 400ms speed with an 85% popin means it scales up quickly and smoothly
hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "fluent_decel", style = "popin 85%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "easeOutExpo", style = "popin 85%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "easeOutQuint" })

-- 3. Fades (Opacity changes)
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "fluent_decel" })
hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 3, bezier = "fluent_decel" })
hl.animation({ leaf = "fadeShadow", enabled = true, speed = 3, bezier = "fluent_decel" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 3, bezier = "fluent_decel" })

-- 4. Layers (Waybar, Wofi, Quickshell, popups)
hl.animation({ leaf = "layers", enabled = true, speed = 4, bezier = "fluent_decel", style = "fade" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 3, bezier = "easeOutExpo", style = "fade" })

-- 5. Borders and Glows (Static transitions, NO LOOPS)
hl.animation({ leaf = "border", enabled = true, speed = 4, bezier = "fluent_decel" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 4, bezier = "linear", style = "once" })

-- 6. Workspaces
-- Workspaces
hl.animation({ leaf = "workspaces",       enabled = true, speed = 3, bezier = "md3_decel", style = "slidefade 15%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3, bezier = "md3_decel", style = "slidevert" })
-- 7. Zoom
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 4, bezier = "fluent_decel" })

-- Ref https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- "Smart gaps" / "No gaps when only"
-- uncomment all if you wish to use that.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name  = "no-gaps-wtv1",
--     match = { float = false, workspace = "w[tv1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
-- hl.window_rule({
--     name  = "no-gaps-f1",
--     match = { float = false, workspace = "f[1]" },
--     border_size = 0,
--     rounding    = 0,
-- })

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
hl.config({
    dwindle = {
        preserve_split = true, -- You probably want this
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
hl.config({
    master = {
        new_status = "master",
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/ for more
hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
    },
})

----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        force_default_wallpaper = 1,    -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo   = true, -- If true disables the random hyprland logo / anime girl background. :(
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    cursor = {
        no_hardware_cursors = 2, -- 2 means auto (disable when tearing)
        use_cpu_buffer = 2,      -- 2 means auto (nvidia only)
        inactive_timeout = 5,    -- Hides the cursor after 5 seconds of inactivity
    },
})

hl.config({
    input = {
        kb_layout  = "us", 
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = -0.4, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.config({
    gestures = {
        workspace_swipe_distance = 300,       -- Distance in px for the touchpad gesture
        workspace_swipe_invert = true,        -- Invert the direction (touchpad only)
        workspace_swipe_cancel_ratio = 0.5,   -- How much the swipe has to proceed in order to commence it
        workspace_swipe_create_new = true,    -- Swiping right on the last workspace creates a new one
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "ALT" -- Sets "Windows" key as main modifier

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
local closeWindowBind = hl.bind(mainMod .. " + Q", hl.dsp.window.close())
-- closeWindowBind:set_enabled(false)
hl.bind("SUPER" .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))    -- dwindle only
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Window Binds 
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true }) 
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), {mouse = true})
hl.bind(mainMod .. " + SHIFT + Left", hl.dsp.window.move({direction = "l"}))
hl.bind(mainMod .. " + SHIFT + Right", hl.dsp.window.move({direction = "r"}))
hl.bind(mainMod .. " + SHIFT + Up", hl.dsp.window.move({direction = "u"}))
hl.bind(mainMod .. " + SHIFT + Down", hl.dsp.window.move({direction = "d"}))
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({direction = "l"}))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({direction = "r"}))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({direction = "u"}))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({direction = "d"}))

--ScreenShot Utility
-- 1.Pick hex color from screen directly to clipboard
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("bash -c 'sleep 0.2 && hyprpicker -a'"))

-- 2.Capture entire monitor and open in Satty editor to annotate/save
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("grim - | satty --filename - --fullscreen --output-filename ~/Pictures/screenshot_$(date +'%Y%m%d_%H%M%S').png"))

-- 3. Drag region -> Open in Satty editor (draw arrows/copy/save)
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("bash -c 'sleep 0.2 && grim -g \"$(slurp)\" - | satty --filename - --output-filename ~/Pictures/screenshot_$(date +\"%Y%m%d_%H%M%S\").png'"))

-- 4. Instant silent region snip directly to clipboard (no editor)
hl.bind(mainMod .. " + CONTROL + S", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy"))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Example window rules that are useful
hl.window_rule({
    match = { 
        class = "com.gabm.satty" 
    },
    float = true,
    center = true,
    pin = true,
})

hl.window_rule({
    match = {
        title = "Authentication Required"
    },
    float = true,
    center = true,
    pin = true,
})

hl.window_rule({
    match = {
        class = "thunar",
        title = "Rename .*"
    },
    float = true,
    center = true,
    pin = true,
})

hl.window_rule({
    name = "vscodium opacity",
    match = { class = "codium" },

    opacity = "0.85 override 0.45 override 1.0 override"
})

hl.window_rule({
    name = "terminal-opacity",
    match = { class = "kitty" },
    -- Use " override" to set an exact value rather than a multiplier
    opacity = "0.8 override 0.55 override 1.0 override", 
})

local suppressMaximizeRule = hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})
