# Theme catalog

Inventory for the Catppuccin → Kanagawa Dragon migration.

This file is reference-only. `docs/**` is excluded by `.chezmoiignore`.

## Migration rules

- Do not replace `catppuccin` strings globally.
- Prefer native Kanagawa Dragon support when an application provides it.
- Use custom palette files when native support is missing.
- Keep background and surfaces near black; reserve saturated colors for state and alerts.
- Do not migrate historical/reference assets until active consumers are confirmed.

## Canonical target palette

| Semantic role | Kanagawa Dragon color |
| --- | --- |
| background | `#0d0c0c` |
| base | `#1d1c19` |
| surface | `#282727` |
| surface-alt | `#393836` |
| border | `#625e5a` |
| text | `#c5c9c5` |
| muted text | `#a6a69c` |
| accent blue | `#8ba4b0` |
| accent cyan | `#8ea4a2` |
| success green | `#8a9a7b` |
| warning yellow | `#c4b28a` |
| secondary orange | `#b6927b` |
| error red | `#c4746e` |
| secondary violet | `#8992a7` |
| secondary pink | `#a292a3` |

Pink and violet should remain unused except where an application requires a
separate semantic color.

## Migration checklist

Detailed file inventory remains in the tables below. This checklist tracks
implementation progress.

### Foundation

- [x] Inventory active theme consumers and reference-only assets.
- [x] Define canonical Kanagawa Dragon palette.
- [x] Document migration rules and cleanup order.

### Terminal, shell, and system information

- [x] **WezTerm** — inline Kanagawa Dragon color scheme and tab palette.
- [x] **Alacritty** — local `kanagawa-dragon.toml` palette and active import.
- [x] **Windows Terminal** — default profile, admin profile, scheme, and UI theme.
- [x] **Starship** — Kanagawa Dragon powerline cards, OS, Git, runtimes,
  Docker/Conda/Pixi, command duration, and clock modules.
- [x] **Fastfetch** — logo placeholders and module colors migrated.
- [ ] Validate Starship in Bash, Zsh, and PowerShell.
- [ ] Validate Fastfetch alternate `ascii`, `gengar`, and `windows` logos.
- [ ] Remove obsolete `dot_config/alacritty/catppuccin-mocha.toml` after
  deployment validation.

### Editors and terminal applications

- [x] **Zed** — Kanagawa Dragon UI theme and neutral `Zed (Default)` icon theme.
- [x] **Zellij** — active themes and `zjstatus` palette migrated; custom
  `dot_config/zellij/themes/kanagawa-dragon.kdl` added. Historical `config.old.kdl`
  remains unchanged.
- [x] **Herdr** — Kanagawa base with Kanagawa Dragon token overrides; light auto-switch disabled.
- [x] **Yazi** — migración terminada: Kanagawa Dragon flavor, plugins actuales,
  previewers y keybindings validados. Piper queda Linux-only por requerir `sh`.
- [x] **btop** — Kanagawa Dragon theme created and selected; legacy themes retained temporarily.
- [x] **micro** — Kanagawa Dragon colorscheme created and selected; legacy schemes retained temporarily.
- [x] **gitui** — inline palette migrated to Kanagawa Dragon.
- [x] **aerc** — descartado; configuración eliminada.
- [x] **ytm-player** — Kanagawa Dragon color overrides active through `theme.toml` on registered `ytm-dark` theme.

### Desktop integration

- [x] **Vesktop** — System24 selected with Kanagawa Dragon QuickCSS overrides; no Catppuccin URL.
- [x] **Warp** — Kanagawa Dragon theme added; select it from Warp theme settings.
- [x] **GlazeWM** — Catppuccin anchors removed; focused and unfocused borders use Dragon colors.
- [x] **YASB** — CSS variables and direct Catppuccin colors migrated to Kanagawa Dragon.
- [x] **Rainmeter** — sideCat palette migrated; Trashy Kanagawa Dragon variant added.
- [x] **Windows setup** — SecureUxTheme switched to Kanagawa Wave Night SQR; registry accents use Dragon violet palette.
- [x] **Windows cursors** — Kanagawa cursor pack registered as `Kanagawa-Cursors` and selected by chezmoi.
- [x] **Flow Launcher** — Kanagawa Dragon XAML theme created and selected.
- [x] **Ditto** — Kanagawa Dragon XML theme created for Win+V clipboard.
- [x] **Nilesoft Shell** — context-menu theme migrated to Kanagawa Dragon.
- [ ] Confirm whether legacy Hyprlock theme tree is still deployed.

### Final cleanup

- [ ] Search active configuration for remaining Catppuccin references.
- [ ] Remove orphaned Catppuccin themes, flavors, modules, and submodules.
- [ ] Run `chezmoi diff` and application-specific config validation.
- [ ] Perform final visual review on Windows and Linux.

## Active configuration surfaces

### Cross-platform

| Application | Files | Current state | Migration work |
| --- | --- | --- | --- |
| Zed | `dot_config/zed/settings.json` | Dark theme `Kanagawa Dragon`; icons use `Zed (Default)` | Validate visually in Zed |
| WezTerm | `dot_config/wezterm/wezterm.lua` | Migrated to inline Kanagawa Dragon scheme and tab palette | Validate visually; no Catppuccin dependency remains |
| Alacritty | `dot_config/alacritty/alacritty.toml`; `dot_config/alacritty/kanagawa-dragon.toml` | Imports local Kanagawa Dragon file | Validate Windows deployment path; retire old Catppuccin file later |
| btop | `dot_config/btop/btop.conf`; `dot_config/btop/themes/kanagawa_dragon.theme` | Active theme `kanagawa_dragon`; legacy bundled themes retained temporarily | Validate visually; remove unused bundles later |
| micro | `dot_config/micro/settings.json`; `dot_config/micro/colorschemes/kanagawa-dragon.micro` | Active `kanagawa-dragon`; legacy schemes retained temporarily | Validate visually; remove unused schemes later |
| Starship | `dot_config/starship.toml` | Prompt and active palette migrated to Kanagawa Dragon; old Catppuccin palettes removed | Validate prompt in Bash, Zsh, and PowerShell |
| Yazi | `dot_config/yazi/theme.toml`; `init.lua`; `package.toml`; `keymap.toml`; `yazi.toml.tmpl` | Migrated completely to Kanagawa Dragon; current plugins and previewers configured | Visual review optional; Piper is Linux-only because it requires `sh` |
| Fastfetch | `dot_config/fastfetch/config.jsonc`; `ascii.txt`; `gengar*.txt`; `windows*.txt` | Logo placeholders and module colors migrated to Kanagawa Dragon | Validate alternate logo files later |
| ytm-player | `dot_config/ytm-player/config.toml`; `theme.toml` | Registered theme `ytm-dark` with active Kanagawa Dragon overrides; legacy Catppuccin theme retained temporarily | Validate visually; remove legacy theme later |

### Linux

| Application | Files | Current state | Migration work |
| --- | --- | --- | --- |
| Zellij | `dot_config/zellij/config.kdl`; `config.defaults.kdl`; `config.lockunlock.kdl`; `themes/kanagawa-dragon.kdl`; `config.old.kdl` | Active configs use custom `kanagawa-dragon`; `zjstatus` uses Dragon values; `.old` remains historical Catppuccin | Validate on Linux; remove or archive `.old` during final cleanup |
| Herdr | `dot_config/herdr/config.toml.tmpl` | Built-in Kanagawa base with Dragon overrides; fixed dark mode | Validate after deployment; no light Dragon variant |
| aerc | — | Descartado; configuración retirada del repositorio | No action |
| gitui | `dot_config/gitui/theme.ron` | Active inline Kanagawa Dragon palette; current patch fields only | Validate visually; legacy Catppuccin references are gone |
| Vesktop | `dot_config/vesktop/settings/settings.json`; `settings/quickCss.css` | System24 selected; Kanagawa Dragon palette overrides active; no Catppuccin URL | Validate visually in Vesktop |
| Hyprlock legacy | `dot_config/hypr.old/hyprlock/catppuccin/`; `.gitmodules` | Legacy/old Hyprlock tree and Catppuccin submodule | Confirm whether tree is still deployed before touching |

No current `waybar`, `kitty`, or `ghostty` theme surface was found in tracked
configuration. Do not create replacements for them.

### Windows

| Application/system | Files | Current state | Migration work |
| --- | --- | --- | --- |
| Windows Terminal | `AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json` | Default, admin profile, scheme, and UI theme migrated to Kanagawa Dragon | Validate visually; remove stale external references if found |
| Warp | `AppData/Roaming/warp/Warp/data/themes/kanagawa_dragon.yml` | Kanagawa Dragon theme added; legacy Catppuccin themes retained temporarily | Select and validate visually in Warp; remove unused flavors later |
| GlazeWM | `dot_glzr/glazewm/config.yaml` | Inline Catppuccin anchors removed; focused border `#8992a7`, other border `#393836` | Validate visually in GlazeWM |
| YASB | `dot_config/yasb/styles.css`; `dot_config/yasb/config.yaml` | CSS variables and direct palette colors use Kanagawa Dragon; system-specific app colors retained | Validate widget states visually |
| Rainmeter | `AppData/Roaming/Rainmeter/Layouts/sideCat/Rainmeter.ini`; `Documents/Rainmeter/Skins/sideCat/@Resources/styles.inc`; `Documents/Rainmeter/Skins/Trashy/Kanagawa Dragon.ini` | sideCat uses Dragon palette; Kanagawa Dragon Trashy variant added; legacy Trashy variants untouched | Select Kanagawa Dragon variant and validate visually; remove unused variants later |
| Windows setup | `.chezmoiscripts/run_once_after_07_windows-setup.ps1.tmpl`; `program_files/windows/resources/themes/Kanagawa*` | Starts Kanagawa Wave Night SQR through SecureUxTheme; writes Dragon violet accent palette | Apply and validate after elevated chezmoi run; Wave is used because no Dragon `.msstyles` exists |
| Windows cursors | `.chezmoi.toml.tmpl`; `.chezmoiscripts/run_onchange_05_windows-cursors.ps1.tmpl`; `program_files/windows/cursors/Kanagawa-Cursors/` | Installs and selects `Kanagawa-Cursors` from the Kanagawa Wave cursor assets | Apply elevated cursor script and validate pointer states visually |
| Flow Launcher | `AppData/Roaming/FlowLauncher/Settings/Settings.json`; `Themes/Kanagawa Dragon.xaml` | Active `Kanagawa Dragon` XAML theme; legacy Catppuccin theme retained | Validate visually in Flow Launcher |
| Ditto | `program_files/ditto/Themes/kanagawa-dragon.xml` | Kanagawa Dragon XML theme available; deployed by Windows program-files script | Select theme in Ditto and validate Win+V visually |
| Nilesoft Shell | `program_files/nilesoft/imports/theme.nss` | Active `modern` context-menu theme uses Kanagawa Dragon colors | Reload Nilesoft Shell and validate context menus visually |
| Alacritty | `dot_config/alacritty/alacritty.toml` | Imports local Kanagawa Dragon palette through the Windows deployment path | Validate deployed path and retire old Catppuccin file later |
| PowerShell module | `Documents/PowerShell/Modules/Catppuccin/` | Palette helper module present; no tracked callers found | Verify installed usage; likely cleanup candidate |

## Bundled or reference-only assets

These contain Catppuccin but are not active configuration references or are
excluded from deployment. Migrate only after active consumers are stable.

- `dot_config/btop/themes/catppuccin_*.theme`
- `dot_config/micro/colorschemes/catppuccin-*.micro`
- `dot_config/yazi/flavors/catppuccin-*.yazi/`
- `AppData/Roaming/warp/Warp/data/themes/catppuccin_*.yml`
- `program_files/windows/resources/themes/Catppuccin *.theme`
- `program_files/windows/cursors/Catppuccin-*`
- `program_files/ditto/Themes/catppuccin-mocha-mauve.xml`
- `Documents/PowerShell/Modules/Catppuccin/`
- `Documents/Rainmeter/Skins/Trashy/{Latte,Frappe,Macchiato,Mocha}.ini`
- `dot_config/hypr.old/hyprlock/catppuccin/`

`program_files/**` and `other_config/**` are reference-only according to
`.chezmoiignore`.

## Non-theme matches

The following can mention Catppuccin without being part of active color
rendering: licenses, READMEs, historical configs, external metadata, and
comments. Remove them only during final cleanup.

## Planned migration order

1. Create Kanagawa files/mappings for terminal and editor surfaces.
2. Migrate shell/TUI surfaces.
3. Migrate Linux/Windows desktop bars and window manager accents.
4. Validate with `chezmoi diff`, config parsers, application reloads, and a
   final active-reference search.
5. Delete orphaned Catppuccin assets and dependencies only after validation.
