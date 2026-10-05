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
| `AppData/Roaming/vesktop/settings/` | `~/AppData/Roaming/vesktop/settings/` | Windows-only (System24 + Kanagawa QuickCSS); Linux uses `dot_config/vesktop/`. Vencord junction points here |
| `AppData/Local/.../WindowsTerminal/settings.json` | `~/AppData/Local/...` | |

## Windows junctions

Apps that don't respect `$HOME` or need a folder-level link are handled via junctions in `.chezmoiscripts/run_once_setup-windows-symlinks.ps1.tmpl`.

| Junction target (live) | Source in chezmoi | App |
|-----------------------|-------------------|-----|
| `~/scoop/persist/btop/btop.conf` | `dot_config/btop/btop.conf` | btop (file symlink) |
| `~/AppData/Roaming/Zed` | `dot_config/zed` | Zed editor |
| `~/AppData/Roaming/yazi/config` | `dot_config/yazi` | Yazi file manager |
| `~/AppData/Roaming/Vencord/settings` | `AppData/Roaming/vesktop/settings` | Vencord/Vesktop (shared settings) |
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
| `Documents/AutoHotkey/` | AutoHotkey automation scripts |
| `Documents/Rainmeter/Skins/` | Rainmeter desktop widgets (sideCat, Trashy) |

## Package commands

```powershell
backup -Manager uv
restore -Manager uv
update -Manager mise
update -Manager mise,uv,npm
```

`-Manager` accepts one or more names and skips the restore manager menu, not
package/profile selection. Without parameters, `backup` and `update` process all
supported managers; `restore` opens its existing menu. Duplicate names run once.
`update-all` / `upgrade-all` always update all managers and reject `-Manager`.
Supported per-manager aliases remain available.

Backup managers: `winget`, `scoop`, `npm`, `bun`, `pnpm`, `uv`, `bin`, `cargo`,
`herdr`. Restore also supports `winget-elevated`. Update supports
`winget`, `scoop`, `npm`, `bun`, `pnpm`, `uv`, `mise`.
Herdr's `-Plugin`, `-All`, and `-Yes` require `-Manager herdr` alone.

The tracked npm/bun/pnpm and uv inventories have been retired on Windows too.
The Linux mise configuration does not replace them. Until fresh inventories
are generated on Windows, these tools cannot be restored from this repository;
restore/bootstrap menus omit missing inventories. Run `backup -Manager npm,bun,pnpm,uv`
after installing the desired tools on Windows to generate new local inventories.
Backup commands create missing inventory directories, including `node/`.

## uv tools

```powershell
backup -Manager uv
restore -Manager uv
update -Manager uv
```

`backup-uv` saves `packages/windows/uv-tools.txt` using native uv metadata:
package extras, original registry version constraints, Python major/minor, and
additional `--with` registry requirements (including version exclusions).
For example:

```text
harlequin[mysql] --python 3.13
headroom-ai[all] --python 3.12 --with ast-grep-cli>=0.30.0,!=0.44.0,!=0.44.1
```

Query errors, warnings about skipped/broken tools, or invalid metadata leave
the inventory and its `.bak` untouched. Unsupported sources/specifications fail
rather than exporting a lossy entry.
Old name-only lists still work. Backup, restore, and the Windows install template
keep their uv validation/parsing inside each script, without an external helper.
Restore and bootstrap pass each argument separately, without `Invoke-Expression`.
Native uv installation checks existing tools instead of
skipping them by name. Failed restores/updates terminate before success messages;
bootstrap installations record failures in their existing summary.

This is not a lockfile: Python patches, resolved dependency versions, custom
indexes/options, and extras/markers on additional requirements are not preserved
by this native-list-based inventory. Preserve those separately; only restore
trusted packages. Regenerate the Windows inventory on Windows, not from Linux.

## mise tools

Keep Windows-compatible global/project mise configuration versioned, including
tool versions/options, custom plugin sources, environment variables, and tasks.
After restoring trusted configuration and installing mise/required plugins:

```powershell
mise install
```

`backup` and `restore` no longer include mise; historical `mise-tools.txt`
inventories and `.bak` files remain untouched but are not used for restoration.
The Linux `dot_config/mise/config.toml` remains excluded on Windows: preserve
Windows-compatible configuration separately rather than copying Linux-only tools.

`update -Manager mise` (also `update-mise` / `upgrade-mise`) still runs
`mise upgrade` for the current configuration, preserving version ranges without
`--bump`. `update-all` / `upgrade-all` includes it. The mise executable remains
managed by Scoop or its original package manager.

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
- `dot_config/wezterm/wezterm.lua` — WezTerm terminal
- `dot_tmux.conf.tmpl` — psmux native tmux-compatible config (`~/.tmux.conf`)
- `program_files/ditto/` — Ditto clipboard manager (portable)
- `program_files/nilesoft/` — Nilesoft Shell (portable)
- `packages/windows/` — Package lists and Windhawk settings
