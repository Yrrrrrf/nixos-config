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

hl.monitor({ output = "eDP-1",    mode = "2560x1600@165",  position = "0x0",    scale = 1 })
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
    hl.exec_cmd("uwsm app -- awww-daemon")
    hl.exec_cmd("uwsm app -- hypridle")
    hl.exec_cmd("uwsm app -- dunst")
    hl.exec_cmd("uwsm app -- wl-paste --watch cliphist store")
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
local exec    = hl.dsp.exec_cmd

-- Prepend the mod key to a chord; hardware keys call hl.bind directly.
local function chord(keys) return mainMod .. " + " .. keys end

-- "Press chord -> run shell command" binds.
local app_binds = {
  ["M"]               = "uwsm stop",
  ["return"]          = terminal,
  ["SHIFT + return"]  = "wezterm start --class floating-term --cwd $HOME/Downloads",
  ["E"]               = "wezterm start --class floating-term -- yazi $HOME/Downloads",
  ["SHIFT + E"]       = fileManager,
  ["space"]           = "uwsm app -- " .. menu,
  ["escape"]          = "layout --change",
  ["ALT + S"]         = "screenshot --region",
  ["ALT + SHIFT + S"] = "screenshot --screen",
  ["ALT + V"]         = "clipboard --pick",
}
for keys, cmd in pairs(app_binds) do hl.bind(chord(keys), exec(cmd)) end

-- Window / layout actions (dispatchers, not shell commands).
local window_binds = {
  ["W"]         = hl.dsp.window.close(),
  ["V"]         = hl.dsp.window.float({ action = "toggle" }),
  ["SHIFT + J"] = hl.dsp.layout("togglesplit"),
  ["P"]         = hl.dsp.window.pseudo(),
}
for keys, action in pairs(window_binds) do hl.bind(chord(keys), action) end

-- Vim-style focus.
for key, dir in pairs({ h = "left", l = "right", k = "up", j = "down" }) do
  hl.bind(chord(key), hl.dsp.focus({ direction = dir }))
end

-- Arrow-key resize.
local resize = {
  left  = { x = -16, y =   0, relative = true },
  right = { x =  16, y =   0, relative = true },
  up    = { x =   0, y = -16, relative = true },
  down  = { x =   0, y =  16, relative = true },
}
for key, step in pairs(resize) do
  hl.bind(chord(key), hl.dsp.window.resize(step), { repeating = true })
end

-- Workspaces 1-10 (focus + move).
for i = 1, 10 do
  local key = i % 10
  hl.bind(chord(key),               hl.dsp.focus({ workspace = i }))
  hl.bind(chord("SHIFT + " .. key), hl.dsp.window.move({ workspace = i }))
end

-- Special workspaces (scratchpads): toggle + move.
for key, name in pairs({ S = "magic", X = "scratch" }) do
  hl.bind(chord(key),               hl.dsp.workspace.toggle_special(name))
  hl.bind(chord("SHIFT + " .. key), hl.dsp.window.move({ workspace = "special:" .. name }))
end

-- Mouse: workspace scroll + drag.
hl.bind(chord("mouse_down"), hl.dsp.focus({ workspace = "e+1" }))
hl.bind(chord("mouse_up"),   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(chord("mouse:272"),  hl.dsp.window.drag(), { mouse = true })
-- hl.bind(chord("mouse:273"), hl.dsp.window.move_resize(), { mouse = true })

-- Hardware keys: locked + repeating, no mod prefix.
local hw_flags = { locked = true, repeating = true }
for key, cmd in pairs({
  XF86AudioRaiseVolume  = "volume --up",
  XF86AudioLowerVolume  = "volume --down",
  XF86AudioMute         = "volume --mute",
  XF86AudioMicMute      = "mic --toggle",
  XF86MonBrightnessUp   = "brightness --up",
  XF86MonBrightnessDown = "brightness --down",
}) do
  hl.bind(key, exec(cmd), hw_flags)
end

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
