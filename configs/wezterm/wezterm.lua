-- WezTerm configuration for Windows with custom keybindings
local wezterm = require 'wezterm'
local config = {}

-- Use config builder object if available (newer WezTerm versions)
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- Font configuration
config.font = wezterm.font('Cascadia Code', { weight = 'Regular' })
config.font_size = 11.0

-- Cool color scheme and background
config.color_scheme = 'Tokyo Night'

-- Window configuration with cool effects
config.window_background_opacity = 0.85
config.window_decorations = "RESIZE"
config.window_close_confirmation = "NeverPrompt"

-- Cool background gradient
config.window_background_gradient = {
  colors = { '#1a1b26', '#24283b', '#414868' },
  orientation = { Linear = { angle = -45.0 } },
  interpolation = 'Linear',
  blend = 'Rgb',
}

-- Add some blur effect (Windows 11 acrylic-like)
config.win32_system_backdrop = 'Acrylic'

-- Cool window padding
config.window_padding = {
  left = 20,
  right = 20,
  top = 20,
  bottom = 20,
}

-- Tab bar configuration
config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false

-- Shell configuration for Windows
config.default_prog = { 'powershell.exe' }
-- Alternative: Use Command Prompt
-- config.default_prog = { 'cmd.exe' }
-- Alternative: Use Windows Subsystem for Linux
-- config.default_prog = { 'wsl.exe' }

-- Key bindings with custom shortcuts
config.keys = {
  -- Split panes (custom keybindings)
  {
    key = 'f',
    mods = 'ALT|SHIFT',
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  {
    key = 'd',
    mods = 'ALT|SHIFT',
    action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
  },

  -- Navigate between panes (Arrow keys)
  {
    key = 'LeftArrow',
    mods = 'ALT',
    action = wezterm.action.ActivatePaneDirection 'Left',
  },
  {
    key = 'RightArrow',
    mods = 'ALT',
    action = wezterm.action.ActivatePaneDirection 'Right',
  },
  {
    key = 'UpArrow',
    mods = 'ALT',
    action = wezterm.action.ActivatePaneDirection 'Up',
  },
  {
    key = 'DownArrow',
    mods = 'ALT',
    action = wezterm.action.ActivatePaneDirection 'Down',
  },

  -- Close pane
  {
    key = 'w',
    mods = 'ALT|SHIFT',
    action = wezterm.action.CloseCurrentPane { confirm = true },
  },

  -- Resize panes
  {
    key = 'LeftArrow',
    mods = 'ALT|SHIFT',
    action = wezterm.action.AdjustPaneSize { 'Left', 5 },
  },
  {
    key = 'RightArrow',
    mods = 'ALT|SHIFT',
    action = wezterm.action.AdjustPaneSize { 'Right', 5 },
  },
  {
    key = 'UpArrow',
    mods = 'ALT|SHIFT',
    action = wezterm.action.AdjustPaneSize { 'Up', 5 },
  },
  {
    key = 'DownArrow',
    mods = 'ALT|SHIFT',
    action = wezterm.action.AdjustPaneSize { 'Down', 5 },
  },

  -- Tab management
  {
    key = 't',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.SpawnTab 'CurrentPaneDomain',
  },
  {
    key = 'w',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.CloseCurrentTab { confirm = true },
  },

  -- Switch tabs with Ctrl+Alt+Number
  {
    key = '1',
    mods = 'CTRL|ALT',
    action = wezterm.action.ActivateTab(0),
  },
  {
    key = '2',
    mods = 'CTRL|ALT',
    action = wezterm.action.ActivateTab(1),
  },
  {
    key = '3',
    mods = 'CTRL|ALT',
    action = wezterm.action.ActivateTab(2),
  },
  {
    key = '4',
    mods = 'CTRL|ALT',
    action = wezterm.action.ActivateTab(3),
  },
  {
    key = '5',
    mods = 'CTRL|ALT',
    action = wezterm.action.ActivateTab(4),
  },

  -- Copy/Paste (using standard terminal shortcuts)
  {
    key = 'c',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.CopyTo 'Clipboard',
  },
  {
    key = 'v',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.PasteFrom 'Clipboard',
  },

  -- Find/Search (works in any shell including cmd.exe)
  {
    key = 'f',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.Search { CaseSensitiveString = '' },
  },
  -- Add reverse history search for cmd.exe
  {
    key = 'r',
    mods = 'CTRL',
    action = wezterm.action.Search { CaseSensitiveString = '' },
  },

  -- Toggle fullscreen
  {
    key = 'F11',
    mods = '',
    action = wezterm.action.ToggleFullScreen,
  },

  -- Zoom
  {
    key = '=',
    mods = 'CTRL',
    action = wezterm.action.IncreaseFontSize,
  },
  {
    key = '-',
    mods = 'CTRL',
    action = wezterm.action.DecreaseFontSize,
  },
  {
    key = '0',
    mods = 'CTRL',
    action = wezterm.action.ResetFontSize,
  },
}

-- Mouse bindings
config.mouse_bindings = {
  -- Right click paste
  {
    event = { Up = { streak = 1, button = 'Right' } },
    mods = 'NONE',
    action = wezterm.action.PasteFrom 'Clipboard',
  },
}

return config
