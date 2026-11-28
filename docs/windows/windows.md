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
| `AppData/Roaming/AltSnap/AltSnap.ini` | `~/AppData/Roaming/AltSnap/` | Window management |
| `AppData/Roaming/alacritty/` | `~/AppData/Roaming/alacritty/` | Terminal config |
| `AppData/Roaming/gnupg/` | `~/AppData/Roaming/gnupg/` | GPG config |
| `AppData/Roaming/warp/` | `~/AppData/Roaming/warp/` | Only catppuccin_*.yml and purpulish.yaml themes tracked |
| `AppData/Roaming/ytm-player/` | `~/AppData/Roaming/ytm-player/` | auth.json, history.db, session.json gitignored |
| `AppData/Local/.../WindowsTerminal/settings.json` | `~/AppData/Local/...` | |

## Windows junctions

Apps that don't respect `$HOME` or need a folder-level link are handled via junctions in `.chezmoiscripts/run_onchange_02_windows-junctions.ps1.tmpl` (list in `packages/windows/system/junctions.json`).

| Junction target (live) | Source in chezmoi | App |
|-----------------------|-------------------|-----|
| `~/scoop/persist/btop/btop.conf` | `dot_config/btop/btop.conf` | btop (file symlink) |
| `~/AppData/Roaming/Zed` | `dot_config/zed` | Zed editor |
| `~/AppData/Roaming/yazi/config` | `dot_config/yazi` | Yazi file manager |
| `~/AppData/Roaming/Zellij/config`    | `dot_config/zellij`           | Zellij terminal multiplexer      |
| `~/AppData/Roaming/gitui`            | `dot_config/gitui`            | Gitui TUI git client             |

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
| `Documents/PowerShell/Functions/secrets.ps1` | Manual secret refresh with `fzf`, backed by `packages/windows/system/secrets.json` |
| `Documents/PowerShell/Functions/backup.ps1` | `backup-herdr` saves Windows inventory to `packages/windows/herdr-plugins.json` without commit refs; `backup` includes it |
| `Documents/PowerShell/Functions/restore.ps1` | Reads Windows inventory from `packages/windows/herdr-plugins.json`; `restore -Manager herdr -All -Yes` restores all; use `-Plugin id1,id2` to select. `-Yes` accepts plugin trust prompts |

## Package commands

```powershell
backup -Manager winget,scoop
restore -Manager mise
update -Manager mise,scoop
```

`-Manager` accepts one or more names and skips the restore manager menu, not
package/profile selection. Without parameters, `backup` and `update` process all
supported managers; `restore` opens its existing menu. Duplicate names run once.
`update-all` / `upgrade-all` always update all managers and reject `-Manager`.
Supported per-manager aliases remain available.

Backup managers: `winget`, `scoop`, `herdr`. Restore also supports
`winget-elevated` and `mise`. Update supports `winget`, `scoop`, `mise`.
Herdr's `-Plugin`, `-All`, and `-Yes` require `-Manager herdr` alone.

## mise tools

mise is the only manager for global CLI tools (npm, PyPI, cargo and GitHub
release binaries); npm/bun/pnpm/uv/bin/cargo are no longer installed, backed up,
restored or updated by these scripts. Their old Windows inventories
(`bin-packages.txt`, `cargo/`) were moved into mise configuration.

Windows reads two chezmoi-managed files:

- `dot_config/mise/config.toml` — every tool for both systems; `os = ["windows"]`
  (aube, GitHub release apps, cargo tools) or `os = ["linux"]` gates the
  platform-specific ones. `mise lock` on Linux also locks the Windows-only
  tools for Windows, so the one `mise.lock` covers both (`locked = true`).

Settings in `config.toml` use `locked = true`: after adding a tool run
`mise lock` on Windows to record it. Restore with:

```powershell
mise trust --all
mise install
```

`restore -Manager mise` (or the bootstrap script) does exactly that.
`update -Manager mise` (also `update-mise` / `upgrade-mise`) runs
`mise upgrade`, preserving version ranges without `--bump`. `update-all` /
`upgrade-all` includes it. The mise executable itself is managed by Scoop.
The pnpm/uv/npm configuration files stay: they only harden project-level
installs and the `uv` calls mise makes for `pypi:` tools.

## Scripts

| Script | Description |
|--------|-------------|
| `.chezmoiscripts/run_once_00_windows-install.ps1.tmpl` | Bootstrap and interactive winget/scoop/mise install |
| `.chezmoiscripts/run_onchange_01_windows-secrets.ps1.tmpl` | Writes API keys from Bitwarden (needs `enable_secrets`) |
| `.chezmoiscripts/run_onchange_02_windows-junctions.ps1.tmpl` | Creates the junctions in `junctions.json` |
| `.chezmoiscripts/run_onchange_03_windows-startup.ps1.tmpl` | Registers the entries in `startup.json` |
| `.chezmoiscripts/run_onchange_04_windows-nilesoft.ps1.tmpl` | Nilesoft Shell context menu imports |
| `.chezmoiscripts/run_once_after_07_windows-setup.ps1.tmpl` | Starts the `startup.json` apps once |
| `.chezmoiscripts/run_onchange_after_08_windows-mise-integration.ps1.tmpl` | Adds the mise shims to the user `PATH` and creates Start Menu shortcuts for the portable mise apps in `packages/windows/system/shortcuts.json` (re-runs when `mise.lock` changes) |
| `.chezmoiscripts/run_once_after_10_windows-aether.ps1.tmpl` | Installs Aether (pinned in `packages/windows/system/aether.json`) last, after the files are applied (it ends in a window of its own, so nothing waits behind it) |

## Desktop shell

Aether (Caelestia on Quickshell) is the Windows desktop: bar, launcher, dashboard, notifications,
lock screen, wallpaper and colours. AetherWM, its Hyprland-compatible window manager, reads
`~/.config/hypr/hyprland.conf` (`dot_config/hypr/`, Windows only; on Linux NixOS owns Hyprland).
Aether's own settings live in `~/.config/caelestia` and are not tracked yet.

## Other Windows configs

- `dot_config/ohmyposh/` — Oh My Posh prompt theme
- `dot_config/wezterm/wezterm.lua` — WezTerm terminal
- `dot_tmux.conf.tmpl` — psmux native tmux-compatible config (`~/.tmux.conf`)
- `program_files/nilesoft/` — Nilesoft Shell (portable)
- `packages/windows/` — Package lists, startup/junction lists and the pinned Aether release
