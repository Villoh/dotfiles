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

--- Returns the Catppuccin colour scheme name based on the current OS appearance.
--- Automatically switches between Mocha (dark) and Latte (light) when the system
--- theme changes — no manual toggle needed.
---
---@param  appearance string  Value from wezterm.gui.get_appearance()
---@return string             Colour scheme name registered in WezTerm
local function scheme_for_appearance(appearance)
  if appearance:find "Dark" then
    return "Catppuccin Mocha"
  else
    return "Catppuccin Latte"
  end
end

--- Catppuccin Mocha palette — used to style the tab bar without relying
--- on the built-in fancy tab bar, giving us full control over its colours.
local mocha = {
  base    = "#1e1e2e",
  mantle  = "#181825",
  crust   = "#11111b",
  text    = "#cdd6f4",
  subtext = "#a6adc8",
  surface = "#313244",
  overlay = "#6c7086",
  blue    = "#89b4fa",
  mauve   = "#cba6f7",
}

-- =============================================================================
-- CONFIG BUILDER
-- =============================================================================

--- wezterm.config_builder() gives us type-checked config with better error
--- messages. Falls back gracefully on older WezTerm versions.
local config = wezterm.config_builder and wezterm.config_builder() or {}

-- =============================================================================
-- THEME — Catppuccin (auto dark / light)
-- =============================================================================

config.color_scheme = scheme_for_appearance(wezterm.gui.get_appearance())

-- Override tab bar colours to match Catppuccin Mocha regardless of the active
-- scheme (avoids a jarring mismatch when the scheme is Latte).
config.colors = {
  tab_bar = {
    background       = mocha.crust,
    active_tab       = { bg_color = mocha.base,   fg_color = mocha.blue,    intensity = "Bold" },
    inactive_tab     = { bg_color = mocha.mantle, fg_color = mocha.subtext  },
    inactive_tab_hover = { bg_color = mocha.surface, fg_color = mocha.text  },
    new_tab          = { bg_color = mocha.crust,  fg_color = mocha.overlay  },
    new_tab_hover    = { bg_color = mocha.surface, fg_color = mocha.text    },
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
  { key = "Backspace", mods = "CTRL", action = act.SendKey    { key = "w", mods = "CTRL" }  },  -- delete prev word
  -- { key = "Backspace", mods = "ALT",  action = act.SendString "\x1b\x7f"                    },  -- delete prev word (alt) — secuencia VT, no convertible
  { key = "Delete",    mods = "CTRL", action = act.SendString "\x1b[3;5~"                   },  -- delete next word — secuencia VT, no convertible

  -- ---------------------------------------------------------------------------
  -- Word navigation
  -- ---------------------------------------------------------------------------
  -- { key = "LeftArrow",  mods = "ALT",  action = act.SendString "\x1b[1;3D"                  },  -- Alt+← word back
  -- { key = "RightArrow", mods = "ALT",  action = act.SendString "\x1b[1;3C"                  },  -- Alt+→ word forward
  { key = "LeftArrow",  mods = "CTRL", action = act.SendString "\x1b[1;5D"                  },  -- Ctrl+← word back — secuencia VT, no convertible
  { key = "RightArrow", mods = "CTRL", action = act.SendString "\x1b[1;5C"                  },  -- Ctrl+→ word forward — secuencia VT, no convertible

  -- ---------------------------------------------------------------------------
  -- Line navigation
  -- ---------------------------------------------------------------------------
  { key = "Home", mods = "NONE", action = act.SendString "\x1b[H"                           },  -- Start of line — secuencia VT, no convertible
  { key = "End",  mods = "NONE", action = act.SendString "\x1b[F"                           },  -- End of line — secuencia VT, no convertible


  -- ---------------------------------------------------------------------------
  -- Scrolling
  -- ---------------------------------------------------------------------------
  { key = "PageUp",   mods = "SHIFT", action = act.ScrollByPage(-1)         },
  { key = "PageDown", mods = "SHIFT", action = act.ScrollByPage(1)          },
  { key = "Home",     mods = "SHIFT", action = act.ScrollToTop              },
  { key = "End",      mods = "SHIFT", action = act.ScrollToBottom           },

  -- ---------------------------------------------------------------------------
  -- Font size
  -- ---------------------------------------------------------------------------
  { key = "+", mods = "CTRL", action = act.IncreaseFontSize                 },
  { key = "-", mods = "CTRL", action = act.DecreaseFontSize                 },
  { key = "0", mods = "CTRL", action = act.ResetFontSize                    },

  -- ---------------------------------------------------------------------------
  -- Tabs (native in WezTerm — no tmux needed)
  -- ---------------------------------------------------------------------------
  { key = "T",   mods = "CTRL|SHIFT", action = act.SpawnTab "CurrentPaneDomain"          },  -- New tab
  { key = "Q",   mods = "CTRL|SHIFT", action = act.CloseCurrentTab { confirm = false }   },  -- Close tab
  { key = "Tab", mods = "CTRL",       action = act.ActivateTabRelative(1)                },  -- Next tab
  { key = "Tab", mods = "CTRL|SHIFT", action = act.ActivateTabRelative(-1)               },  -- Prev tab

  -- ---------------------------------------------------------------------------
  -- Windows
  -- ---------------------------------------------------------------------------
  { key = "N", mods = "CTRL|SHIFT", action = act.SpawnWindow                },  -- New window

  -- ---------------------------------------------------------------------------
  -- Splits — native WezTerm feature, replaces the need for tmux
  -- Ctrl+Shift+D → vertical split   (side by side)
  -- Ctrl+Shift+E → horizontal split (top / bottom)
  -- Alt+Shift+D  → auto split (matches Windows Terminal Alt+Shift+D)
  -- ---------------------------------------------------------------------------
  { key = "D", mods = "CTRL|SHIFT", action = act.SplitVertical   { domain = "CurrentPaneDomain" } },
  { key = "E", mods = "CTRL|SHIFT", action = act.SplitHorizontal { domain = "CurrentPaneDomain" } },
  { key = "D", mods = "ALT|SHIFT",  action = act.EmitEvent "smart-split" },  -- Auto split BSP-style

  -- ---------------------------------------------------------------------------
  -- Pane navigation — Ctrl+Alt+Arrow
  -- ---------------------------------------------------------------------------
  { key = "LeftArrow",  mods = "CTRL|ALT", action = act.ActivatePaneDirection "Left"  },
  { key = "RightArrow", mods = "CTRL|ALT", action = act.ActivatePaneDirection "Right" },
  { key = "UpArrow",    mods = "CTRL|ALT", action = act.ActivatePaneDirection "Up"    },
  { key = "DownArrow",  mods = "CTRL|ALT", action = act.ActivatePaneDirection "Down"  },

  -- ---------------------------------------------------------------------------
  -- Pane management
  -- ---------------------------------------------------------------------------
  { key = "W", mods = "CTRL|SHIFT", action = act.CloseCurrentPane { confirm = false }  },  -- Cerrar pane (no el tab)
  { key = "Z", mods = "CTRL|SHIFT", action = act.TogglePaneZoomState                  },  -- Zoom toggle del pane activo

  -- Redimensionar pane — Ctrl+Alt+Shift+Flechas
  { key = "LeftArrow",  mods = "CTRL|ALT|SHIFT", action = act.AdjustPaneSize { "Left",  5 } },
  { key = "RightArrow", mods = "CTRL|ALT|SHIFT", action = act.AdjustPaneSize { "Right", 5 } },
  { key = "UpArrow",    mods = "CTRL|ALT|SHIFT", action = act.AdjustPaneSize { "Up",    5 } },
  { key = "DownArrow",  mods = "CTRL|ALT|SHIFT", action = act.AdjustPaneSize { "Down",  5 } },

  -- ---------------------------------------------------------------------------
  -- Search (bonus — replaces Windows Terminal Ctrl+Shift+F)
  -- ---------------------------------------------------------------------------
  { key = "F", mods = "CTRL|SHIFT", action = act.Search { CaseSensitiveString = "" } },
}

return config
