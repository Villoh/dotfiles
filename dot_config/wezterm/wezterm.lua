-- =============================================================================
-- WezTerm Configuration
-- =============================================================================
-- Path (Windows): %USERPROFILE%\.wezterm.lua
-- Path (Linux/Mac): ~/.wezterm.lua
-- Docs: https://wezfurlong.org/wezterm/config/files.html
-- =============================================================================

local wezterm = require "wezterm"
local act     = wezterm.action

-- =============================================================================
-- HELPERS
-- =============================================================================

--- Kanagawa Dragon palette.
local dragon = {
  background = "#0d0c0c",
  base       = "#1d1c19",
  surface    = "#282727",
  surface_alt = "#393836",
  border     = "#625e5a",
  text       = "#c5c9c5",
  muted      = "#a6a69c",
  blue       = "#8ba4b0",
  cyan       = "#8ea4a2",
  green      = "#8a9a7b",
  yellow     = "#c4b28a",
  orange     = "#b6927b",
  red        = "#c4746e",
  violet     = "#8992a7",
  pink       = "#a292a3",
}

--- Vercel Geist palette (dark). Available as an alternate color_scheme,
--- not activated below — Kanagawa Dragon stays the active scheme.
local geist = {
  background = "#0a0a0a",
  base       = "#1a1a1a",
  surface    = "#1f1f1f",
  surface_alt = "#292929",
  border     = "#454545",
  text       = "#ededed",
  muted      = "#a1a1a1",
  blue       = "#0072f5",
  cyan       = "#12a594",
  green      = "#45a557",
  yellow     = "#ffb224",
  orange     = "#ff990a",
  red        = "#e5484d",
  violet     = "#8e4ec6",
  pink       = "#ea3e83",
}

-- =============================================================================
-- CONFIG BUILDER
-- =============================================================================

--- wezterm.config_builder() gives us type-checked config with better error
--- messages. Falls back gracefully on older WezTerm versions.
local config = wezterm.config_builder and wezterm.config_builder() or {}

-- =============================================================================
-- THEME — Kanagawa Dragon
-- =============================================================================

config.color_schemes = {
  ["Kanagawa Dragon"] = {
    background = dragon.background,
    foreground = dragon.text,
    cursor_bg = dragon.text,
    cursor_fg = dragon.background,
    selection_bg = dragon.surface_alt,
    selection_fg = dragon.text,
    ansi = {
      dragon.background, dragon.red, dragon.green, dragon.yellow,
      dragon.blue, dragon.pink, dragon.cyan, dragon.muted,
    },
    brights = {
      dragon.border, dragon.red, dragon.green, dragon.yellow,
      dragon.blue, dragon.violet, dragon.cyan, dragon.text,
    },
  },
  ["Vercel Geist"] = {
    background = geist.background,
    foreground = geist.text,
    cursor_bg = geist.text,
    cursor_fg = geist.background,
    selection_bg = geist.surface_alt,
    selection_fg = geist.text,
    ansi = {
      geist.background, geist.red, geist.green, geist.yellow,
      geist.blue, geist.pink, geist.cyan, geist.muted,
    },
    brights = {
      geist.border, geist.red, geist.green, geist.yellow,
      geist.blue, geist.violet, geist.cyan, geist.text,
    },
  },
}

config.color_scheme = "Kanagawa Dragon"

config.colors = {
  tab_bar = {
    background         = dragon.background,
    active_tab         = { bg_color = dragon.base,    fg_color = dragon.blue,   intensity = "Bold" },
    inactive_tab       = { bg_color = dragon.surface, fg_color = dragon.muted  },
    inactive_tab_hover = { bg_color = dragon.surface_alt, fg_color = dragon.text },
    new_tab            = { bg_color = dragon.background, fg_color = dragon.border },
    new_tab_hover      = { bg_color = dragon.surface_alt, fg_color = dragon.text },
  },
}

-- =============================================================================
-- FONT
-- =============================================================================
-- Primary: CaskaydiaCove Nerd Font (same as Alacritty / Windows Terminal config)
-- Install: winget install -e --id DEVCOM.JetBrainsMonoNerdFont
-- Fallback chain ensures glyphs are always found even if the primary is missing.

config.font = wezterm.font_with_fallback {
  { family = "CaskaydiaCove Nerd Font", weight = "Regular" },
  { family = "JetBrains Mono",          weight = "Regular" },
  "Noto Color Emoji",
}
config.font_size         = 12.0
config.harfbuzz_features = { "calt=1", "clig=1", "liga=1" }  -- Enable ligatures

-- =============================================================================
-- SHELL
-- =============================================================================
-- PowerShell 7+ as default shell, same as the Alacritty config.
-- Install: winget install Microsoft.PowerShell

config.default_prog      = { "pwsh", "--login" }
config.warn_about_missing_glyphs = false

-- =============================================================================
-- WINDOW
-- =============================================================================

config.window_decorations        = "RESIZE"          -- No title bar
config.window_padding            = { left = 12, right = 12, top = 12, bottom = 12 }
config.initial_cols              = 120
config.initial_rows              = 35
config.window_background_opacity = 0.95            -- 0.0 = transparent · 1.0 = solid
config.win32_system_backdrop     = "Acrylic"       -- Background blur — Windows 11 only
                                                    -- Use "Auto" on Windows 10
config.window_close_confirmation = "NeverPrompt"   -- Close without the "are you sure?" dialog

-- Automatically reload the config file on save — no restart needed.
config.automatically_reload_config = true

-- Prevent the window from resizing when changing font size via keybind.
config.adjust_window_size_when_changing_font_size = false

-- =============================================================================
-- CURSOR
-- =============================================================================

config.default_cursor_style  = "BlinkingBar"   -- Bar shape, blinking (WezTerm llama "Bar" a lo que Alacritty llama "Beam")
config.cursor_blink_rate     = 500             -- ms between blinks
config.cursor_blink_ease_in  = "Constant"      -- No fade-in animation
config.cursor_blink_ease_out = "Constant"      -- No fade-out animation

-- =============================================================================
-- SCROLLBACK
-- =============================================================================

config.scrollback_lines = 10000

-- =============================================================================
-- TAB BAR
-- =============================================================================

config.enable_tab_bar               = true
config.hide_tab_bar_if_only_one_tab = true   -- Hidden when there's only one tab, like Alacritty
config.use_fancy_tab_bar            = false  -- Use our custom colour scheme above
config.tab_bar_at_bottom            = false
config.tab_max_width                = 32

--- Emula el split automático BSP de Windows Terminal.
--- Usa dimensiones en píxeles para decidir el eje de corte:
--- más ancho que alto → split vertical (lado a lado)
--- más alto que ancho → split horizontal (arriba/abajo)
wezterm.on("smart-split", function(window, pane)
  local dim = pane:get_dimensions()
  wezterm.log_info("pixel_width: " .. dim.pixel_width .. " pixel_height: " .. dim.pixel_height)

  if dim.pixel_width > dim.pixel_height then
    window:perform_action(act.SplitHorizontal { domain = "CurrentPaneDomain" }, pane)
  else
    window:perform_action(act.SplitVertical { domain = "CurrentPaneDomain" }, pane)
  end
end)

-- =============================================================================
-- KEY BINDINGS
-- =============================================================================
-- We keep WezTerm's default bindings and only add/override what we need,
-- matching the behaviour from the Alacritty and Windows Terminal configs.

config.keys = {

  -- ---------------------------------------------------------------------------
  -- Clipboard
  -- ---------------------------------------------------------------------------
  { key = "C", mods = "CTRL|SHIFT", action = act.CopyTo "Clipboard"    },
  { key = "V", mods = "CTRL|SHIFT", action = act.PasteFrom "Clipboard" },

  -- ---------------------------------------------------------------------------
  -- Word editing
  -- ---------------------------------------------------------------------------
  { key = "Backspace", mods = "CTRL", action = act.SendKey { key = "w", mods = "CTRL" } },  -- delete prev word
  { key = "Delete",    mods = "CTRL", action = act.SendString "\x1b[3;5~"               },  -- delete next word

  -- ---------------------------------------------------------------------------
  -- Word navigation
  -- ---------------------------------------------------------------------------
  { key = "LeftArrow",  mods = "CTRL", action = act.SendString "\x1b[1;5D" },  -- Ctrl+← word back
  { key = "RightArrow", mods = "CTRL", action = act.SendString "\x1b[1;5C" },  -- Ctrl+→ word forward

  -- ---------------------------------------------------------------------------
  -- Line navigation
  -- ---------------------------------------------------------------------------
  { key = "Home", mods = "NONE", action = act.SendString "\x1b[H" },
  { key = "End",  mods = "NONE", action = act.SendString "\x1b[F" },

  -- ---------------------------------------------------------------------------
  -- Scrolling
  -- ---------------------------------------------------------------------------
  { key = "PageUp",   mods = "SHIFT", action = act.ScrollByPage(-1)  },
  { key = "PageDown", mods = "SHIFT", action = act.ScrollByPage(1)   },
  { key = "Home",     mods = "SHIFT", action = act.ScrollToTop       },
  { key = "End",      mods = "SHIFT", action = act.ScrollToBottom    },

  -- ---------------------------------------------------------------------------
  -- Font size
  -- ---------------------------------------------------------------------------
  { key = "+", mods = "CTRL", action = act.IncreaseFontSize },
  { key = "-", mods = "CTRL", action = act.DecreaseFontSize },
  { key = "0", mods = "CTRL", action = act.ResetFontSize    },

  -- ---------------------------------------------------------------------------
  -- Tabs
  -- ---------------------------------------------------------------------------
  { key = "t",   mods = "ALT",        action = act.SpawnTab "CurrentPaneDomain"        },  -- New tab
  { key = "t",   mods = "ALT|SHIFT",  action = act.CloseCurrentTab { confirm = false } },  -- Close tab
  { key = "q",   mods = "ALT|SHIFT",  action = act.CloseCurrentTab { confirm = false } },  -- Close tab (alt)
  { key = ".",   mods = "ALT",        action = act.ActivateTabRelative(1)              },  -- Next tab
  { key = ",",   mods = "ALT",        action = act.ActivateTabRelative(-1)             },  -- Prev tab
  { key = "Tab", mods = "CTRL",       action = act.ActivateTabRelative(1)              },  -- Next tab
  { key = "Tab", mods = "CTRL|SHIFT", action = act.ActivateTabRelative(-1)             },  -- Prev tab
  { key = "1",   mods = "ALT",        action = act.ActivateTab(0)                      },
  { key = "2",   mods = "ALT",        action = act.ActivateTab(1)                      },
  { key = "3",   mods = "ALT",        action = act.ActivateTab(2)                      },
  { key = "4",   mods = "ALT",        action = act.ActivateTab(3)                      },
  { key = "5",   mods = "ALT",        action = act.ActivateTab(4)                      },
  { key = "6",   mods = "ALT",        action = act.ActivateTab(5)                      },
  { key = "7",   mods = "ALT",        action = act.ActivateTab(6)                      },
  { key = "8",   mods = "ALT",        action = act.ActivateTab(7)                      },
  { key = "9",   mods = "ALT",        action = act.ActivateTab(8)                      },

  -- ---------------------------------------------------------------------------
  -- Windows
  -- ---------------------------------------------------------------------------
  { key = "N", mods = "CTRL|SHIFT", action = act.SpawnWindow },

  -- ---------------------------------------------------------------------------
  -- Splits
  -- Alt+d → split abajo · Alt+e → split derecha · Alt+Shift+D → auto BSP
  -- ---------------------------------------------------------------------------
  { key = "d", mods = "ALT",       action = act.SplitVertical   { domain = "CurrentPaneDomain" } },
  { key = "e", mods = "ALT",       action = act.SplitHorizontal { domain = "CurrentPaneDomain" } },
  { key = "n", mods = "ALT",       action = act.EmitEvent "smart-split" },  -- BSP auto split
  { key = "D", mods = "ALT|SHIFT", action = act.EmitEvent "smart-split" },  -- BSP auto split (alt)

  -- ---------------------------------------------------------------------------
  -- Pane navigation — Alt+hjkl y Alt+flechas
  -- ---------------------------------------------------------------------------
  { key = "h",          mods = "ALT", action = act.ActivatePaneDirection "Left"  },
  { key = "j",          mods = "ALT", action = act.ActivatePaneDirection "Down"  },
  { key = "k",          mods = "ALT", action = act.ActivatePaneDirection "Up"    },
  { key = "l",          mods = "ALT", action = act.ActivatePaneDirection "Right" },
  { key = "LeftArrow",  mods = "ALT", action = act.ActivatePaneDirection "Left"  },
  { key = "DownArrow",  mods = "ALT", action = act.ActivatePaneDirection "Down"  },
  { key = "UpArrow",    mods = "ALT", action = act.ActivatePaneDirection "Up"    },
  { key = "RightArrow", mods = "ALT", action = act.ActivatePaneDirection "Right" },

  -- ---------------------------------------------------------------------------
  -- Pane management
  -- ---------------------------------------------------------------------------
  { key = "x", mods = "ALT",       action = act.CloseCurrentPane { confirm = false } },  -- Close pane
  { key = "w", mods = "ALT|SHIFT", action = act.CloseCurrentPane { confirm = false } },  -- Close pane (alt)
  { key = "z", mods = "ALT",       action = act.TogglePaneZoomState                 },  -- Zoom pane

  -- Resize — Alt+Shift+hjkl y Alt+Shift+flechas
  { key = "h",          mods = "ALT|SHIFT", action = act.AdjustPaneSize { "Left",  5 } },
  { key = "j",          mods = "ALT|SHIFT", action = act.AdjustPaneSize { "Down",  5 } },
  { key = "k",          mods = "ALT|SHIFT", action = act.AdjustPaneSize { "Up",    5 } },
  { key = "l",          mods = "ALT|SHIFT", action = act.AdjustPaneSize { "Right", 5 } },
  { key = "LeftArrow",  mods = "ALT|SHIFT", action = act.AdjustPaneSize { "Left",  5 } },
  { key = "DownArrow",  mods = "ALT|SHIFT", action = act.AdjustPaneSize { "Down",  5 } },
  { key = "UpArrow",    mods = "ALT|SHIFT", action = act.AdjustPaneSize { "Up",    5 } },
  { key = "RightArrow", mods = "ALT|SHIFT", action = act.AdjustPaneSize { "Right", 5 } },

  -- ---------------------------------------------------------------------------
  -- Search
  -- ---------------------------------------------------------------------------
  { key = "F", mods = "CTRL|SHIFT", action = act.Search { CaseSensitiveString = "" } },
}

return config
