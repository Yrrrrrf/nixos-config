local wezterm = require 'wezterm'
local config = {}

config.font = wezterm.font("JetBrainsMono Nerd Font Mono")
config.window_background_opacity = 0.95

-- Stylix will handle colors in the end, but we can add placeholders if we want
-- For now, let's just keep it simple as it was.

return config
