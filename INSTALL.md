# Installation Guide

> [!WARNING]
> **This installation is not 100% tested and is still under construction. Use at your own risk.**

> [!NOTE]
> Package selection is interactive — the install script uses [fzf](https://github.com/junegunn/fzf) to let you pick exactly which packages to install. You can also review and edit the lists beforehand in [`packages/windows/`](packages/windows/) (Windows) or [`packages/linux/`](packages/linux/) (Linux).

## Prerequisites

### Windows

> [!IMPORTANT]
> Open **Terminal as Administrator** before running the install command. Some winget packages require elevation and will prompt UAC individually if the terminal is not elevated.

Install **Git** and **chezmoi** via winget:

```powershell
winget install -e --id Git.Git
winget install -e --id twpayne.chezmoi
```

### Linux

Install **Git** and **chezmoi** via pacman:

```bash
sudo pacman -S git chezmoi
```

---

## Install

```bash
chezmoi init --apply --exclude=encrypted github.com/Villoh/dotfiles
```

During `init --apply`, chezmoi will:
1. Clone the repo to `~/.local/share/chezmoi`
2. Prompt for module enable/disable options (all default to `true`)
3. Generate `~/.config/chezmoi/chezmoi.toml`
4. Create symlinks for all managed files

chezmoi runs scripts automatically in this order:

**Phase 1 — before files (run_once / run_onchange, by numeric prefix):**

| Script | What it does |
|--------|--------------|
| `run_once_00_windows-install` *(Windows)* | Bootstrap (Scoop, fzf, Dev Mode, Node, Bun, uv, bin) + interactive package install (winget, scoop, npm, bun, uv, PowerShell modules, bin, cargo) + GlazeWM win-keys |
| `run_once_01_windows-secrets` *(Windows)* | Fetches API keys from Bitwarden (or prompts manually) and writes them to `~/Documents/PowerShell/Secrets/api-keys.ps1` |
| `run_onchange_02_windows-junctions` *(Windows)* | Junctions for apps that can't use chezmoi symlinks |
| `run_onchange_03_windows-startup` *(Windows)* | Startup registry entries |
| `run_onchange_04_windows-program-files` *(Windows)* | Deploys Ditto/Nilesoft configs and Windows themes |
| `run_onchange_05_windows-cursors` *(Windows)* | Installs cursor theme |
| `run_onchange_06_windows-windhawk` *(Windows)* | Deploys Windhawk mod configs and registry settings |
| `run_once_00_linux-install` *(Linux)* | Git submodules, bootstrap (paru, flatpak, Node, Bun, uv, bin) + packages (pacman/AUR, flatpak, npm, bun, uv, bin) |

> Scripts run in numeric prefix order (00, 01, 02…).

**Phase 2 — chezmoi applies all files and symlinks**

**Phase 3 — after files (run_after, by numeric prefix):**

| Script | What it does |
|--------|--------------|
| `run_once_after_07_windows-setup` *(Windows)* | Accent color, theme |
| `run_onchange_after_08_windows-wallpaper` *(Windows)* | Desktop wallpaper + lock screen (requires `~/Pictures/Wallpapers/` symlink to exist) |

---

## Manual steps (Windows)

Some steps require manual intervention and are exposed as PowerShell functions available in any session after install.

### GPG as SSH agent

Only needed if you want to use your GPG authentication subkey for SSH:

```powershell
setup-gpg-ssh
```

### WSL distro setup

Launches an fzf picker to select a distro, installs it, and sets up packages (Arch: locale + pacman + AUR):

```powershell
setup-wsl
```

> Requires WSL installed (included in winget packages). Uses fzf to pick the distro — locale, user creation, and packages are configured automatically.

### Spicetify Marketplace

The Marketplace config (theme + extensions) is backed up at `other_config/spicetify/spicetify-marketplace.json`.

**Current setup:**
- Theme: **Comfy** — scheme `catppuccin-mocha`
- Extensions: Shuffle+, Bookmark, Full Screen, adblockify

1. Install Spicetify and patch Spotify:
   ```powershell
   winget install Spicetify.Spicetify
   spicetify backup apply
   ```

2. Install Spicetify Marketplace:
   ```powershell
   iwr -useb https://raw.githubusercontent.com/spicetify/marketplace/main/resources/install.ps1 | iex
   ```

3. Open Spotify → **Marketplace → Settings (gear icon) → Import backup** → load `other_config/spicetify/spicetify-marketplace.json`.

Marketplace will reinstall the theme and all extensions automatically.

> To update the backup: **Marketplace → Settings → Export backup** → overwrite the file → commit with `chore(spicetify): update marketplace backup`.

---

## Re-running scripts

chezmoi tracks script state in two buckets:
- `scriptState` — `run_once_` scripts, keyed by content hash
- `entryState` — `run_onchange_` scripts, keyed by destination path

```powershell
# Re-run all run_once_ scripts on next apply
reset-run-once-scripts && chezmoi apply

# Re-run a specific run_onchange_ script on next apply
reset-run-onchange-script windows-setup && chezmoi apply
reset-run-onchange-script windows-wallpaper && chezmoi apply

# Re-run all run_onchange_ scripts on next apply
reset-run-onchange-script && chezmoi apply
```

Run a script manually without resetting state (renders the template first):
```powershell
# Windows
Get-Content "$(chezmoi source-path)\.chezmoiscripts\run_once_windows-install.ps1.tmpl" |
    chezmoi execute-template | powershell -NoProfile -Command -

# Linux
chezmoi execute-template "$(chezmoi source-path)/.chezmoiscripts/run_once_linux-install.sh.tmpl" | bash
```
