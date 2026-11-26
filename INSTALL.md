# Installation Guide

> [!WARNING]
> **This installation is not 100% tested and is still under construction. Use at your own risk.**

> [!NOTE]
> Windows package selection is interactive. Linux uses NixOS/Home Manager as
> its declarative source of truth; this repository does not install Linux
> packages.

## Installation flow

Every operating-system guide ends at a working OS. The shared handoff is:

1. Install Git, GnuPG, OpenSSH, and chezmoi.
2. Import the private GPG key and ownertrust from a secure backup.
3. Start and verify the GPG/SSH agent when SSH authentication is required.
4. Initialize chezmoi without applying files.
5. Verify decryption with `chezmoi diff`.
6. Apply the dotfiles and validate Git signing and SSH.

See [`docs/install/bootstrap.md`](docs/install/bootstrap.md) for the complete
procedure and the reason for this ordering.

## One-shot install (Windows, CLI)

In any PowerShell window:

```powershell
irm https://raw.githubusercontent.com/Villoh/dotfiles/main/install.ps1 | iex
```

[`install.ps1`](install.ps1) runs entirely in the terminal. It relaunches itself as
Administrator, installs Git, Gpg4win and chezmoi with winget, and asks for the
personal or secondary flow. Then it runs `chezmoi init` with its usual prompts.
For the personal flow it imports the GPG key from the paths you enter, seeds
the GPG/SSH agent files and checks decryption with `chezmoi diff`. Last, it
runs `chezmoi apply`, where packages are chosen with fzf.

## GUI install (Windows)

A separate flow, for those who prefer a window:

```powershell
irm https://raw.githubusercontent.com/Villoh/dotfiles/main/install-gui.ps1 | iex
```

[`install-gui.ps1`](install-gui.ps1) relaunches itself as Administrator, downloads
`dotfiles-installer.exe` from the latest `installer-v*` release, checks its
SHA-256 against the release's `SHA256SUMS` and runs it. The installer GUI
([`installer/`](installer)) covers the same flow:

1. **Prerequisites**: installs the missing Git, Gpg4win and chezmoi with winget
   and clones the repository to `chezmoi source-path`.
2. **GPG key**: personal flow (imports the secret key and ownertrust) or
   secondary flow (`--exclude=encrypted`).
3. **Profile**: `install_profile`, `enable_secrets` and, for `custom`, each
   module. They are passed to `chezmoi init` as `--promptChoice`/`--promptBool`.
4. **Packages**: the winget, winget (elevated) and scoop checklists. The choice
   is written to a JSON file named by `DOTFILES_PACKAGE_SELECTION`, which
   `run_once_00_windows-install` reads instead of asking with fzf.
5. **Install**: `chezmoi init`, then for the personal flow it seeds the GPG/SSH
   agent files and checks decryption with `chezmoi diff`. Last, `chezmoi apply`
   runs in its own console window, where the scripts can ask questions.

To publish a new installer build: `git tag installer-vX.Y.Z && git push origin installer-vX.Y.Z`
(see `.github/workflows/installer.yml`). To build it locally:
`cd installer && GOOS=windows go build -ldflags "-H=windowsgui" -o dotfiles-installer.exe .`

The manual steps below do the same thing by hand.

## Prerequisites

### Windows

> [!IMPORTANT]
> Open **Terminal as Administrator** before running the install command. Some winget packages require elevation and will prompt UAC individually if the terminal is not elevated.

Install **Git**, **GnuPG/Gpg4win**, and **chezmoi** via winget:

```powershell
winget install -e --id Git.Git
winget install -e --id GnuPG.Gpg4win
winget install -e --id twpayne.chezmoi
```

Import the private GPG key before applying the repository. See the [common
bootstrap guide](docs/install/bootstrap.md).

### Linux

The Linux system must be configured with **NixOS + Hyprland + Dank Material
Shell (DMS)** separately. Install Git, GnuPG, OpenSSH, and chezmoi
declaratively through NixOS/Home Manager. Then follow the [common bootstrap
guide](docs/install/bootstrap.md).

Do not use pacman/AUR or the old Arch bootstrap flow on NixOS.

---

## Install

### Personal flow — with private GPG keys

Use this flow on your own machine. Import the private GPG key and ownertrust,
then follow the [common bootstrap guide](docs/install/bootstrap.md):

```bash
chezmoi init https://github.com/Villoh/dotfiles
chezmoi diff
chezmoi apply
```

Do not apply until GnuPG can decrypt the encrypted files. On Windows, open an
Administrator terminal before running the Windows package-install scripts.

### Secondary flow — without private keys

Use this flow for a secondary machine or another user who must not receive the
encrypted personal configuration:

```bash
chezmoi init --apply --exclude=encrypted https://github.com/Villoh/dotfiles
```

This intentionally skips encrypted Git identities, work configuration,
secrets, and other private files. Configure that machine's Git identity and
SSH credentials separately. If the private GPG key is imported later, run:

```bash
chezmoi diff
chezmoi apply
```

During initialization, chezmoi will:
1. Clone the repo to `~/.local/share/chezmoi`
2. Ask for an install profile (see below)
3. Generate `~/.config/chezmoi/chezmoi.toml`
4. Create symlinks for all managed files

### Install profile

`chezmoi init` asks for a profile, stored as `install_profile` in `chezmoi.toml`:

| Profile | Result |
|---------|--------|
| `full` | Every module for the current OS. Windows package profile = `full`. |
| `minimal` | CLI + shell configs only. Windows: no Aether, Nilesoft, AutoHotkey, Warp or startup entries. Windows package profile = `minimal`. |
| `custom` | Asks `Enable <module>` for each module (Enter keeps the previous answer, default `true`). Windows package profile is chosen in fzf. |

Each answer lives in `[data]` as `enable_<module>`; edit `~/.config/chezmoi/chezmoi.toml`
before `chezmoi apply` to change one without re-running init. The Windows desktop is one toggle,
`enable_aether`: it installs Aether and deploys `~/.config/hypr/hyprland.conf` for AetherWM.
Re-running `chezmoi init` keeps the stored profile; to pick another, edit `install_profile`.

chezmoi runs scripts automatically in this order:

**Phase 1 — before files (run_once / run_onchange, by numeric prefix):**

**Windows:**

| Script | What it does |
|--------|--------------|
| `run_once_00_windows-install` | Bootstrap (Scoop, fzf, mise, Dev Mode) + interactive package install (winget, scoop, PowerShell modules) + `mise install` for every global CLI tool |
| `run_onchange_01_windows-secrets` | (needs `enable_secrets`) Fetches API keys from Bitwarden (or prompts manually) and writes them to `~/Documents/PowerShell/Secrets/api-keys.ps1` |
| `run_onchange_02_windows-junctions` | Junctions for apps that can't use chezmoi symlinks |
| `run_onchange_03_windows-startup` | Startup registry entries |
| `run_onchange_04_windows-nilesoft` | Copies the Nilesoft Shell imports into Program Files |

**Linux:**

There is no Linux package-installation script. NixOS/Home Manager installs and
updates the system and its packages declaratively.

> Scripts run in numeric prefix order (00, 01, 02…).

**Phase 2 — chezmoi applies all files and symlinks**

**Phase 3 — after files (run_after, by numeric prefix):**

**Windows:**

| Script | What it does |
|--------|--------------|
| `run_once_after_06_windows-aether` | Downloads `AetherSetup.exe` at the version and SHA-256 pinned in `packages/windows/system/aether.json` and runs its setup window (it has no silent mode). Runs after the files are applied so your `hyprland.conf` exists before AetherWM's build could write a starter one. Tick the AetherWM box in that window to get tiling: it is opt-in, built from source and personal-use only |
| `run_once_after_07_windows-setup` | Starts the apps in `startup.json` once (`enable_startup`) |

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
