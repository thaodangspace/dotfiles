-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices
config.font =
  wezterm.font('IBM Plex Mono', { weight = 'Regular' })
-- For example, changing the color scheme:
config.color_scheme = 'Catppuccin Mocha (Gogh)'
config.enable_tab_bar = false
config.window_decorations = "RESIZE"
config.window_background_opacity = 1
config.macos_window_background_blur = 30
-- and finally, return the configuration to wezterm
return config
