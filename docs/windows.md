# Windows configuration

## Running PowerShell commands from bash

The shell in this environment is bash (Git Bash / MSYS2). PowerShell cmdlets are not available directly — use `powershell.exe -NoProfile -Command` to invoke them:

```bash
powershell.exe -NoProfile -Command "Get-ChildItem \$env:APPDATA"
```

For multi-line scripts:

```bash
powershell.exe -NoProfile -Command "
  \$src = \"\$env:APPDATA\MyApp\config.json\";
  Copy-Item \$src 'C:\backup\config.json'
"
```

Prefer `curl` for simple downloads — it's available natively in bash and avoids the quoting overhead:

```bash
curl -L "https://example.com/file.zip" -o "$APPDATA/MyApp/file.zip"
```

## AppData tracked configs

| Path in repo | Deployed to | Notes |
|-------------|-------------|-------|
| `AppData/Roaming/FlowLauncher/Settings/Settings.json` | `~/AppData/Roaming/FlowLauncher/Settings/` | History, cache, plugins gitignored |
| `AppData/Roaming/FlowLauncher/Themes/Catppuccin Mocha.xaml` | same | |
| `AppData/Roaming/AltSnap/AltSnap.ini` | `~/AppData/Roaming/AltSnap/` | Window management |
| `AppData/Roaming/alacritty/` | `~/AppData/Roaming/alacritty/` | Terminal config |
| `AppData/Roaming/gnupg/` | `~/AppData/Roaming/gnupg/` | GPG config |
| `AppData/Roaming/warp/` | `~/AppData/Roaming/warp/` | Only catppuccin_*.yml and purpulish.yaml themes tracked |
| `AppData/Roaming/ytm-player/` | `~/AppData/Roaming/ytm-player/` | auth.json, history.db, session.json gitignored |
| `AppData/Roaming/vesktop/settings/` | via junction (see below) | Shared with Vencord |
| `AppData/Local/.../WindowsTerminal/settings.json` | `~/AppData/Local/...` | |

## Windows junctions

Apps that don't respect `$HOME` or need a folder-level link are handled via junctions in `.chezmoiscripts/run_once_setup-windows-symlinks.ps1.tmpl`.

| Junction target (live) | Source in chezmoi | App |
|-----------------------|-------------------|-----|
| `~/scoop/persist/btop/btop.conf` | `dot_config/btop/btop.conf` | btop (file symlink) |
| `~/AppData/Roaming/Zed` | `dot_config/zed` | Zed editor |
| `~/AppData/Roaming/yazi/config` | `dot_config/yazi` | Yazi file manager |
| `~/AppData/Roaming/Vencord/settings` | `dot_config/vesktop/settings` | Vencord/Vesktop (shared settings) |
| `~/AppData/Roaming/Zellij/config`    | `dot_config/zellij`           | Zellij terminal multiplexer      |

All junctions are built using:
```powershell
$source = ("{{ .chezmoi.sourceDir }}").Replace('/', '\')
```
`chezmoi.sourceDir` returns forward slashes on Windows — the `.Replace` is mandatory.

## Documents

| Path | Description |
|------|-------------|
| `Documents/PowerShell/Microsoft.PowerShell_profile.ps1` | Main PS profile |
| `Documents/PowerShell/Modules/` | Terminal-Icons, PowerToys Configure modules |
| `Documents/PowerShell/Functions/bitwarden.ps1` | Bitwarden CLI helpers (sensitive) |
| `Documents/AutoHotkey/` | AutoHotkey automation scripts |
| `Documents/Rainmeter/Skins/` | Rainmeter desktop widgets (sideCat, Trashy) |

## Scripts

| Script | Description |
|--------|-------------|
| `.chezmoiscripts/run_once_install-packages.ps1` | Installs Scoop packages and Windows tools |
| `.chezmoiscripts/run_once_restore-windhawk.ps1` | Restores Windhawk mods |
| `.chezmoiscripts/run_once_setup-windows-symlinks.ps1.tmpl` | Creates all junctions |
| `.chezmoiscripts/run_onchange_install-ditto-themes.ps1.tmpl` | Ditto clipboard themes |
| `.chezmoiscripts/run_onchange_install-nilesoft-imports.ps1.tmpl` | Nilesoft Shell context menu imports |

## Other Windows configs

- `dot_config/ohmyposh/` — Oh My Posh prompt theme
- `dot_config/yasb/` — YASB status bar
- `dot_config/scoop/` — Scoop config
- `dot_config/wezterm/wezterm.lua` — WezTerm terminal
- `dot_tmux.conf` — psmux native tmux-compatible config (`~/.tmux.conf`)
- `program_files/ditto/` — Ditto clipboard manager (portable)
- `program_files/nilesoft/` — Nilesoft Shell (portable)
- `packages/windows/` — Package lists and Windhawk settings
