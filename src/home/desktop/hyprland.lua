-- ~/.config/hypr/hyprland.lua
-- =====================================================================
-- Hyprland 0.55+ Lua Configuration
-- Tokens like @accent_nohash@ are substituted by Nix at build time
-- via the `theme.apply` function in desktop.nix.
-- =====================================================================


--------------------
---- PROGRAMS ------
--------------------

local terminal    = "wezterm"
local fileManager = "cosmic-files"
local menu        = "walker"


------------------
---- MONITORS ----
------------------

hl.monitor({ output = "eDP-1",    mode = "2560x1600@120",  position = "0x0",    scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "3440x1440@100",  position = "0x-1440", scale = 1 })


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE",    "24")
hl.env("HYPRCURSOR_SIZE", "24")


-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("uwsm app -- waybar")
    hl.exec_cmd("uwsm app -- awww")
    hl.exec_cmd("uwsm app -- hypridle")
    hl.exec_cmd("uwsm app -- dunst")
    hl.exec_cmd("uwsm app -- wl-paste --watch cliphist store")
    -- Wallpaper (awww needs the daemon running first — slight delay is fine)
    hl.exec_cmd("awww img @wallpaper@")
end)


-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in  = 2,
        gaps_out = 4,

        border_size = @borderWidth@,

        col = {
            active_border   = { colors = { "rgb(@accent_nohash@)", "rgb(@accent-alt_nohash@)" }, angle = 45 },
            inactive_border = "rgb(@surface_nohash@)",
        },

        resize_on_border = false,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding         = @borderRadius_island@,
        active_opacity   = 1.00,
        inactive_opacity = 0.94,

        shadow = {
            enabled      = true,
            range        = 20,
            render_power = 3,
            color        = 0x@bg_nohash@ee,
        },

        blur = {
            enabled          = true,
            size             = 3,
            passes           = 1,
            new_optimizations = true,
            ignore_opacity   = true,
            xray             = true,
        },
    },

    animations = {
        enabled = true,
    },
})

-- Bezier curves
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1.0}  } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 3,    bezier = "easeOutQuint", style = "slide" })


-----------------
---- LAYOUTS ----
-----------------

hl.config({
    dwindle = {
        preserve_split = true,
    },
    master = {
        new_status = "master",
    },
})


----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo   = true,
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us, us",
        kb_variant = ", intl",
        kb_options = "caps:swapescape,grp:super_escape_toggle",

        follow_mouse = true,
        sensitivity  = 0,

        touchpad = {
            natural_scroll = true,
        },
    },
})

hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.8,
})


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

-- Core
hl.bind(mainMod .. " + M",           hl.dsp.exec_cmd("uwsm stop"))
hl.bind(mainMod .. " + return",      hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E",           hl.dsp.exec_cmd("wezterm start --class floating-term -- yazi $HOME/Downloads"))
hl.bind(mainMod .. " + SHIFT + E",   hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + space",       hl.dsp.exec_cmd("uwsm app -- " .. menu))
hl.bind(mainMod .. " + W",           hl.dsp.window.close())
hl.bind(mainMod .. " + V",           hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + J",   hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + P",           hl.dsp.window.pseudo())

-- Focus (vim-style)
hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "left"  }))
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "up"    }))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "down"  }))

-- Resize (arrow keys)
hl.bind(mainMod .. " + left",  hl.dsp.window.resize({ x = -16, y =   0 }), { repeating = true })
hl.bind(mainMod .. " + right", hl.dsp.window.resize({ x =  16, y =   0 }), { repeating = true })
hl.bind(mainMod .. " + up",    hl.dsp.window.resize({ x =   0, y = -16 }), { repeating = true })
hl.bind(mainMod .. " + down",  hl.dsp.window.resize({ x =   0, y =  16 }), { repeating = true })

-- Workspaces 1-10
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,           hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key,   hl.dsp.window.move({ workspace = i }))
end

-- Special workspaces (scratchpads)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(mainMod .. " + X",         hl.dsp.workspace.toggle_special("scratch"))
hl.bind(mainMod .. " + SHIFT + X", hl.dsp.window.move({ workspace = "special:scratch" }))

-- Mouse workspace scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Mouse move/resize
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Hardware: audio
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("volume --up"),     { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("volume --down"),   { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("volume --mute"),   { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("mic --toggle"),    { locked = true, repeating = true })

-- Hardware: brightness
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightness --up"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightness --down"), { locked = true, repeating = true })

-- Layout / screenshot / clipboard
hl.bind(mainMod .. " + escape",         hl.dsp.exec_cmd("layout --change"))
hl.bind(mainMod .. " + ALT + S",        hl.dsp.exec_cmd("screenshot --region"))
hl.bind(mainMod .. " + ALT + SHIFT + S",hl.dsp.exec_cmd("screenshot --screen"))
hl.bind(mainMod .. " + ALT + V",        hl.dsp.exec_cmd("clipboard --pick"))

-- Media
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),        { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"),  { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"),  { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),    { locked = true })


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- Floating windows: terminals via --class + selected GUI apps
local floatingClass = "^(floating-term|com\\.system76\\.CosmicFiles)$"

hl.window_rule({
    name  = "floating-apps",
    match = { class = floatingClass },
    float = true,
    size  = "1280 720",
    center = true,
})

-- Suppress maximize events
hl.window_rule({
    name           = "suppress-maximize-events",
    match          = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix XWayland drag issues
hl.window_rule({
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

-- Host-specific binds (written by the host's homeExtras).
-- In Lua configs, `source` is gone — each host's homeExtras
-- should require() their own lua file or use hl.bind directly.
-- The file below is written by g14's homeExtras if present:
pcall(require, "host-extras")
