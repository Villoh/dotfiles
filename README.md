# dotfiles

Personal dotfiles for Windows ([AtlasOS](https://atlasos.net/)), managed with [chezmoi](https://www.chezmoi.io/).

## Overview

- **OS:** Windows 11 (AtlasOS)
- **Manager:** chezmoi with `mode = "symlink"` — every managed file is a symlink to the chezmoi source, so edits take effect immediately without re-adding
- **Encryption:** GPG (`.gitconfig.local`, `gnupg/sshcontrol`)
- **Auto-commit/push:** enabled — changes are committed and pushed automatically after `chezmoi add` / `chezmoi re-add`

## Fresh install

### Prerequisites

1. **Developer Mode** must be enabled (required for symlinks without elevation)
   `Settings → System → For developers → Developer Mode`

2. **GPG** — install [GnuPG for Windows](https://www.gnupg.org/download/) and import your key:
   ```powershell
   gpg --import your-key.asc
   ```

3. **chezmoi** — install via winget:
   ```powershell
   winget install twpayne.chezmoi
   ```

### Apply dotfiles

```powershell
chezmoi init --apply github.com/Villoh/dotfiles
```

This will:
1. Clone the repo to `~/.local/share/chezmoi`
2. Generate `~/.config/chezmoi/chezmoi.toml` from the template
3. Create symlinks for all managed files
4. Run the `run_once_` install scripts (packages + Windhawk)

## Repository structure

```
~/.local/share/chezmoi/
├── .chezmoi.toml.tmpl              # Config template (GPG, symlink mode, git auto-push)
├── .chezmoiignore                  # Paths excluded from apply (Windows-only, caches, state)
├── .gitignore                      # Paths excluded from git tracking
│
├── .chezmoiscripts/
│   ├── run_once_install-packages.ps1     # Installs all packages (see below)
│   └── run_once_restore-windhawk.ps1     # Imports Windhawk settings (elevated)
│
├── packages/windows/               # Package manifests — tracked in repo, not applied to home
│   ├── winget-packages.json
│   ├── scoop-packages.json         # Buckets: main, extras, nerd-fonts
│   ├── chocolatey-packages.config
│   ├── npm-packages.json
│   ├── bun-packages.txt
│   ├── uv-tools.txt
│   ├── bin-packages.txt            # GitHub release binaries (installed via `bin`)
│   └── windhawk-settings.reg
│
├── dot_config/                     # → ~/.config/
│   ├── bin/                        # CLI config
│   ├── cava/                       # Audio visualizer
│   ├── fastfetch/                  # System info (ASCII art, themes)
│   ├── gh-dash/                    # GitHub CLI dashboard
│   ├── micro/                      # Terminal editor (bindings only; backups/buffers ignored)
│   ├── ohmyposh/                   # Shell prompt theme
│   ├── scoop/                      # Scoop user config
│   ├── yasb/                       # Yet Another Status Bar
│   └── zellij/                     # Terminal multiplexer
│
├── AppData/Roaming/                # → %APPDATA%/
│   ├── alacritty/                  # Terminal emulator config + Catppuccin theme
│   ├── warp/                       # Warp terminal themes (previews excluded)
│   ├── FlowLauncher/
│   │   ├── Settings/               # App settings (Plugins/ excluded — reinstall automatically)
│   │   └── Themes/                 # Catppuccin Mocha theme
│   └── gnupg/
│       ├── gpg.conf
│       ├── gpg-agent.conf
│       ├── common.conf
│       └── encrypted_sshcontrol.asc  # GPG-encrypted
│
├── Documents/                      # → ~/Documents/
│   ├── PowerShell/                 # Profile, modules (Terminal-Icons, Catppuccin, etc.)
│   ├── AutoHotkey/                 # Hotkey scripts
│   └── Rainmeter/Skins/            # Desktop widgets
│
├── dot_glzr/glazewm/               # → ~/.glzr/glazewm/ — Tiling window manager config
├── dot_wezterm.lua                 # → ~/.wezterm.lua — WezTerm config
├── dot_gitconfig                   # → ~/.gitconfig
├── encrypted_dot_gitconfig.local.asc  # → ~/.gitconfig.local (GPG-encrypted)
│
└── scoop/persist/btop/             # → ~/scoop/persist/btop/ — btop config + themes
```

## Package managers

The `run_once_install-packages.ps1` script installs everything on a fresh machine:

| Manager    | Source file                    | Notes                              |
|------------|--------------------------------|------------------------------------|
| winget     | `winget-packages.json`         | GUI apps, system tools             |
| scoop      | `scoop-packages.json`          | CLI tools, fonts, dev tools        |
| chocolatey | `chocolatey-packages.config`   | Packages not available elsewhere   |
| npm        | `npm-packages.json`            | Global npm packages (if any)       |
| bun        | `bun-packages.txt`             | Global bun packages                |
| uv         | `uv-tools.txt`                 | Python tools via uv                |
| bin        | `bin-packages.txt`             | GitHub release binaries            |

Scoop buckets: `main`, `extras`, `nerd-fonts`

## Encrypted files

Two files are GPG-encrypted at rest in the repo:

| File                              | Target                        |
|-----------------------------------|-------------------------------|
| `encrypted_dot_gitconfig.local.asc` | `~/.gitconfig.local`        |
| `AppData/Roaming/gnupg/encrypted_sshcontrol.asc` | `%APPDATA%\gnupg\sshcontrol` |

The GPG recipient key is `2E5BD225E500AB50`. chezmoi uses the Windows GnuPG binary at `C:/Program Files/GnuPG/bin/gpg.exe`.

## Daily workflow

Since `mode = "symlink"` is active, all managed files are symlinks to the chezmoi source. Edits are reflected immediately.

```powershell
# Edit a config directly — the change is already in the source
vim ~/.config/ohmyposh/zen.toml

# Commit and push
chezmoi git -- add -A
chezmoi git -- commit -m "Update ohmyposh theme"
# (or just let autoCommit handle it after chezmoi add)

# Add a new file
chezmoi add ~/.config/newapp/config.toml

# Check what's out of sync
chezmoi status

# Pull and apply changes from another machine
chezmoi update
```

## Known quirks

- **Large adds + autoCommit:** Adding 100+ files at once can cause chezmoi's auto-commit to fail (Windows command-line length limit). Workaround: temporarily set `autoCommit = false` in `~/.config/chezmoi/chezmoi.toml`, run `chezmoi add`, commit manually with `chezmoi git -- commit -m "..."`, then re-enable.
- **`Documents/` prefix:** Windows marks shell folders (`Documents`, `Desktop`, etc.) with a `ReadOnly` attribute. If chezmoi ever re-adds files from `Documents/`, rename any `readonly_Documents` back to `Documents` in the source.
- **Warp themes:** The `previews/` subdirectories are excluded (hundreds of SVG files). The themes themselves are fully tracked.
