# dotfiles

Personal dotfiles for **Windows** ([AtlasOS](https://atlasos.net/)) and **Linux** ([CachyOS](https://cachyos.org/) / Hyprland), managed with [chezmoi](https://www.chezmoi.io/).

## Overview

- **Manager:** chezmoi with `mode = "symlink"` — every managed file is a symlink to the chezmoi source, so edits take effect immediately without re-adding
- **Encryption:** GPG (`~/.config/git/local`, `gnupg/sshcontrol`)
- **Secrets scanning:** gitleaks via pre-commit hook
- **Submodules:** sddm and plymouth themes (run `git submodule update --init --recursive` after cloning)

## Fresh install

### Windows

#### Prerequisites

1. **Developer Mode** — required for symlinks without elevation:
   `Settings → System → For developers → Developer Mode`

2. **GPG** — install [GnuPG for Windows](https://www.gnupg.org/download/) and import your key:
   ```powershell
   gpg --import your-key.asc
   ```

3. **chezmoi** — install via winget:
   ```powershell
   winget install twpayne.chezmoi
   ```

#### Apply

```powershell
chezmoi init --apply github.com/Villoh/dotfiles
```

> **Without GPG key**, skip encrypted files:
> ```powershell
> chezmoi init github.com/Villoh/dotfiles
> chezmoi apply --exclude=encrypted
> ```

This will:
1. Clone the repo to `~/.local/share/chezmoi`
2. Generate `~/.config/chezmoi/chezmoi.toml` from the template
3. Create symlinks for all managed files
4. Run `run_once_` scripts: install packages, restore Windhawk, create Windows junctions

### Linux

#### Prerequisites

1. **GPG** — import your key:
   ```bash
   gpg --import your-key.asc
   ```

2. **chezmoi** — install via pacman or the install script:
   ```bash
   sudo pacman -S chezmoi
   ```

#### Apply

```bash
chezmoi init --apply github.com/Villoh/dotfiles
```

> **Without GPG key:**
> ```bash
> chezmoi init github.com/Villoh/dotfiles
> chezmoi apply --exclude=encrypted
> ```

#### Post-install

Install submodules (sddm/plymouth themes):
```bash
cd ~/.local/share/chezmoi
git submodule update --init --recursive
```

Set up gitleaks pre-commit hook:
```bash
uv tool install pre-commit
pre-commit install
```

## Repository structure

```
~/.local/share/chezmoi/
├── .chezmoi.toml.tmpl              # Config template (GPG, symlink mode, git auto-push)
├── .chezmoiignore                  # OS-conditional excludes (Windows-only / Linux-only paths)
├── .gitignore
├── .gitleaks.toml                  # Secrets scanning config
├── .pre-commit-config.yaml         # pre-commit hooks (gitleaks)
│
├── .chezmoiscripts/
│   ├── run_once_install-packages.ps1           # Windows: installs all packages
│   ├── run_once_restore-windhawk.ps1           # Windows: imports Windhawk settings (elevated)
│   └── run_once_setup-windows-symlinks.ps1.tmpl  # Windows: creates junctions/symlinks
│
├── packages/
│   ├── windows/                    # Windows package manifests (winget, scoop, choco, npm, bun, uv)
│   ├── linux/                      # Linux package backups (pacman, aur, flatpak, bun, npm, uv)
│   └── starship/                   # Starship config reference (Linux minimal)
│
├── other_config/                   # Reference only — not applied to home
│   ├── claude/                     # Claude Code/Desktop MCP config docs (sanitized)
│   ├── system/                     # System-level configs (pacman.conf, sdboot)
│   ├── linux-cachyos-pollrate.toml # CachyOS kernel build config
│   ├── plymouth/themes/            # Plymouth boot themes (git submodules)
│   │   ├── adi1090x-themes
│   │   ├── cachyos
│   │   ├── onepiece
│   │   └── vortex-ubuntu
│   └── sddm/themes/                # SDDM login themes (git submodules)
│       └── sddm-astronaut-theme
│
├── program_files/                  # Windows program config files (Ditto, Nilesoft Shell)
│
├── dot_config/                     # → ~/.config/
│   │
│   ├── git/                        # Git config (XDG)
│   │   ├── config                  # Main config (includes local + platform)
│   │   ├── platform.tmpl           # OS-specific settings (rendered per platform)
│   │   └── encrypted_local.asc    # Personal identity + signing key (GPG-encrypted)
│   │
│   ├── zsh/                        # Zsh config (Linux-only)
│   ├── kitty/                      # Kitty terminal (Linux-only)
│   ├── tmux/                       # tmux (Linux-only)
│   ├── hypr/                       # Hyprland WM (Linux-only)
│   ├── waybar/                     # Waybar status bar (Linux-only)
│   ├── swaync/                     # SwayNC notifications (Linux-only)
│   ├── swayosd/                    # SwayOSD overlays (Linux-only)
│   ├── cliphist/                   # Clipboard manager config (Linux-only)
│   ├── autostart/                  # .desktop autostart entries (Linux-only)
│   ├── openvpn/vpnd/               # VPN configs — vpnd only (Linux-only)
│   ├── aerc/                       # Terminal email client (Linux-only)
│   ├── nchat/                      # Terminal chat client (Linux-only)
│   ├── vesktop/                    # Vesktop/Vencord Discord client
│   │                                 # Linux: ~/.config/vesktop/
│   │                                 # Windows: junction from %APPDATA%\Vencord\settings
│   ├── FreeTube/                   # FreeTube settings (Linux-only)
│   ├── ghostty/                    # Ghostty terminal (Linux-only)
│   │
│   ├── zed/                        # Zed editor (cross-platform)
│   │                                 # Windows: junction from %APPDATA%\Zed
│   ├── yazi/                       # Yazi file manager (cross-platform)
│   │                                 # Windows: junction from %APPDATA%\yazi\config
│   ├── btop/                       # btop resource monitor (cross-platform)
│   │                                 # Windows: symlink from ~/scoop/persist/btop/btop.conf
│   ├── starship.toml               # Starship prompt (Windows powerline theme)
│   ├── micro/                      # Terminal editor (bindings + all Catppuccin colorschemes)
│   ├── fastfetch/                  # System info
│   ├── ohmyposh/                   # Oh My Posh prompt theme
│   ├── yasb/                       # Yet Another Status Bar (Windows)
│   ├── cava/                       # Audio visualizer
│   └── ...
│
├── dot_local/bin/                  # → ~/.local/bin/ — personal scripts (Linux-only)
│   ├── dotfiles-sync               # Sync chezmoi repo to GitHub
│   ├── backup-packages             # Backup installed packages to packages/linux/
│   ├── restore-packages            # Interactive package restore (gum)
│   ├── extract-claude-config       # Export sanitized Claude MCP config to other_config/claude/
│   ├── plymouth-themes             # Manage Plymouth boot themes
│   ├── sddm-themes                 # Install SDDM login themes
│   └── ...
│
├── AppData/Roaming/                # → %APPDATA%/ (Windows-only)
│   ├── alacritty/
│   ├── warp/
│   ├── FlowLauncher/
│   └── gnupg/
│       └── encrypted_sshcontrol.asc  # GPG-encrypted
│
├── AppData/Local/Packages/
│   └── Microsoft.WindowsTerminal_.../LocalState/settings.json
│
├── Documents/                      # → ~/Documents/ (Windows-only)
│   ├── PowerShell/
│   ├── AutoHotkey/
│   └── Rainmeter/Skins/
│
└── dot_glzr/glazewm/               # → ~/.glzr/glazewm/ (Windows-only)
```

## Windows junctions

The setup script creates these directory junctions/symlinks, pointing directly to the chezmoi source:

| Junction | → Chezmoi source |
|----------|-----------------|
| `%APPDATA%\Zed` | `dot_config/zed` |
| `%APPDATA%\yazi\config` | `dot_config/yazi` |
| `%APPDATA%\Vencord\settings` | `dot_config/vesktop/settings` |
| `~/scoop/persist/btop/btop.conf` | `dot_config/btop/btop.conf` |

## Encrypted files

| File | Target |
|------|--------|
| `dot_config/git/encrypted_local.asc` | `~/.config/git/local` — name, email, signing key |
| `AppData/Roaming/gnupg/encrypted_sshcontrol.asc` | `%APPDATA%\gnupg\sshcontrol` |

GPG recipient key: `2E5BD225E500AB50`

## Package managers

### Windows (`packages/windows/`)

| Manager    | File                         | Notes                            |
|------------|------------------------------|----------------------------------|
| winget     | `winget-packages.json`       | GUI apps, system tools           |
| scoop      | `scoop-packages.json`        | CLI tools, fonts, dev tools      |
| chocolatey | `chocolatey-packages.config` | Packages not available elsewhere |
| npm        | `npm-packages.json`          | Global npm packages              |
| bun        | `bun-packages.txt`           | Global bun packages              |
| uv         | `uv-tools.txt`               | Python tools                     |

### Linux (`packages/linux/`)

Backups generated by `backup-packages` script:

| File | Contents |
|------|----------|
| `pacman.txt` | Explicitly installed pacman packages |
| `aur.txt` | AUR packages |
| `flatpak.txt` | Flatpak apps |
| `uv-tools.txt` | uv tools |
| `bun-global.txt` | Global bun packages |
| `npm-global.txt` | Global npm packages |

## Daily workflow

```bash
# Edit a config directly — already in source via symlink
vim ~/.config/yazi/yazi.toml

# Sync everything to GitHub
dotfiles-sync

# Add a new file
chezmoi add ~/.config/newapp/config.toml

# Pull and apply from another machine
chezmoi update

# Check status
chezmoi status
```
