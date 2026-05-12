local wezterm = require 'wezterm'
local config = {}

config.font = wezterm.font("@monospace@")
config.window_background_opacity = @opacity@
config.color_scheme = 'Catppuccin Mocha'

-- Standard WezTerm setup
config.hide_tab_bar_if_only_one_tab = true
config.scrollback_lines = 10000

return config
