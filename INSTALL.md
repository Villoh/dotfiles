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

## One-shot install (Linux, CLI)

On a working NixOS, or any other Linux desktop:

```sh
curl -fsSL https://raw.githubusercontent.com/Villoh/dotfiles/main/install.sh | bash
```

[`install.sh`](install.sh) does the same as `install.ps1` minus the package
lists (NixOS/Home Manager installs Linux's packages). First it gets the missing
prerequisites:

| Missing | NixOS | Fedora, Ubuntu/Debian, Arch | Atomic (Bazzite, Silverblue) |
| --- | --- | --- | --- |
| chezmoi | prints the Home Manager line | chezmoi's static build into `~/.local/bin`, pinned and SHA-256 checked, no root | same |
| git, gnupg | prints the Home Manager line | `sudo` with dnf, apt or pacman | `brew install`, or how to layer them |

Then it asks for the personal or secondary flow, runs `chezmoi init`, imports
the GPG key, seeds `~/.gnupg` and `~/.ssh`, checks decryption with `chezmoi diff`
and runs `chezmoi apply`. It reads answers from `/dev/tty`, so it works piped.

## GUI install (Windows and Linux)

A separate flow, for those who prefer a window. Windows:

```powershell
irm https://raw.githubusercontent.com/Villoh/dotfiles/main/install-gui.ps1 | iex
```

Linux:

```sh
curl -fsSL https://raw.githubusercontent.com/Villoh/dotfiles/main/install-gui.sh | bash
# or, with Nix:
nix run github:Villoh/dotfiles
```

[`install-gui.sh`](install-gui.sh) builds the installer from the
[flake](flake.nix) on NixOS, which cannot run AppImages, and elsewhere downloads
`dotfiles-installer-x86_64.AppImage` from the latest release and checks its
SHA-256. The AppImage bundles no libraries: it needs the host's GTK 3. Both
start the installer detached, leaving the terminal free.

```powershell
irm https://raw.githubusercontent.com/Villoh/dotfiles/main/install-gui.ps1 | iex
```

[`install-gui.ps1`](install-gui.ps1) relaunches itself as Administrator, downloads
`dotfiles-installer.exe` from the latest `installer-v*` release, checks its
SHA-256 against the release's `SHA256SUMS` and starts it, leaving the terminal
free. The installer GUI
([`installer/`](installer)) is a native Material 3 app written in Go with
[MyGo](https://github.com/egoist/mygo); its colors follow the Windows accent
color and light/dark mode. It covers the same flow (on Linux, Prerequisites gets
the tools as `install.sh` does, with `pkexec` instead of `sudo` and a copy button
for NixOS's Home Manager line, and there is no Packages page; on NixOS a **System**
page comes first: it clones your NixOS configuration where you choose and runs
`nixos-rebuild test`, then `switch` once the test passes, with `pkexec`):

1. **Atlas** (Windows, optional, first): says where the PC stands (Windows
   edition, and whether Atlas is installed, half installed or missing, read from
   Atlas's own records), downloads the AtlasManager the dotfiles pin
   (`installer/atlas.json`, kept equal to `packages/windows/system/atlas.json` by
   a test), checks its SHA-256 and opens it. Atlas Manager does the rest, which
   needs your hands (four Windows Security switches) and restarts the PC: open
   the installer again afterwards and, seeing Atlas, it starts at Setup. Skip it
   if you do not want Atlas. See [`windows-atlas.md`](docs/install/windows-atlas.md).
2. **Prerequisites**: installs the missing Git, Gpg4win and chezmoi with winget
   and clones the repository to `chezmoi source-path`.
3. **GPG key**: personal flow (imports the secret key and ownertrust) or
   secondary flow (`--exclude=encrypted`).
4. **Profile**: `install_profile`, `enable_secrets` and, for `custom`, each
   module. They are passed to `chezmoi init` as `--promptChoice`/`--promptBool`.
5. **Packages**: the winget, winget (elevated), scoop and mise checklists. The choice
   is written to a JSON file named by `DOTFILES_PACKAGE_SELECTION`, which
   `run_once_00_windows-install` reads instead of asking with fzf.
6. **Install**: `chezmoi init`, then for the personal flow it seeds the GPG/SSH
   agent files and checks decryption with `chezmoi diff`. Last, `chezmoi apply
   --no-tty` runs hidden: its output goes to the log box and, with every other
   log line, to `%TEMP%\dotfiles-installer-<date>.log`. With personal secrets
   on, it runs in a console window instead, where the secrets script asks for
   the Bitwarden login.

The log is under every page and also the last page of the rail (**Log**, or the
expand icon): its text is selectable, the icons copy it (the icon turns into a
check for two seconds) or save the log file, with every line and its time, and
open it in a window of its own, which stays in view while the main window goes
from page to page. Closing that window puts the log back.

### Building and releasing the GUI

- **CI**: `.github/workflows/installer-ci.yml` runs on every push to `main` and
  every pull request that touches the installer, its scripts, the flake,
  `.chezmoi.toml.tmpl` or `packages/windows`. It vets, tests (the tests read the
  real template and package lists), parses the PowerShell scripts, shellchecks
  the shell ones, builds `dotfiles-installer.exe` and the AppImage
  ([`installer/packaging/appimage.sh`](installer/packaging/appimage.sh)) and
  uploads them with `SHA256SUMS` as the `dotfiles-installer` artifact. A second
  job builds the flake: change `vendorHash` in
  [`installer/package.nix`](installer/package.nix) whenever `go.sum` changes.
- **Release**: `.github/workflows/installer-release.yml` builds with the CI
  workflow and publishes a GitHub release on an `installer-v*` tag:

  ```sh
  git tag installer-v0.1.0 && git push origin installer-v0.1.0
  ```

  `install-gui.ps1` and `install-gui.sh` download the latest release; the flake
  builds `main`.
- **Local build**, from any OS (pure Go, no cgo):

  ```sh
  cd installer
  GOOS=windows CGO_ENABLED=0 go build -trimpath -ldflags "-s -w -H=windowsgui" \
    -tags mygo_nodownload,mygo_noinspector -o dotfiles-installer.exe .
  ```

- **Screenshots without a window**: `INSTALLER_SNAPSHOT=/tmp/shot go test -run Snapshot`
  renders every page, light and dark, to PNGs (`INSTALLER_GOOS=linux` for Linux's
  pages). Text needs Pango; on NixOS put pango, glib, cairo, fontconfig and
  harfbuzz in `LD_LIBRARY_PATH`.

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

On a new PC, apply [AtlasOS](docs/install/windows-atlas.md) first (the GUI's first
page does it): it needs a fresh Windows and is not part of `chezmoi apply`.

### Linux

The Linux system must be configured with **NixOS + Hyprland + Dank Material
Shell (DMS)** separately. Install Git, GnuPG, OpenSSH, and chezmoi
declaratively through NixOS/Home Manager. Then run `install.sh` or the GUI
above, or follow the [common bootstrap guide](docs/install/bootstrap.md) by
hand.

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
| `minimal` | CLI and shell configs, and the desktop (Aether on Windows, DMS on Linux), for a new user; no coding-agent configs (`ai_agents`). Windows: no Nilesoft, AltSnap, Warp or startup entries. Windows package profile = `minimal`. |
| `custom` | Asks `Enable <module>` for each module (Enter keeps the previous answer, default `true`). Windows package profile is chosen in fzf. |

Each answer lives in `[data]` as `enable_<module>`; edit `~/.config/chezmoi/chezmoi.toml`
before `chezmoi apply` to change one without re-running init. The Windows desktop is one toggle,
`enable_aether`: it installs Aether and deploys `~/.config/hypr/hyprland.conf` for AetherWM.
`enable_ai_agents` covers the coding agents' configs (`.claude`, `.codex`, `.grok`,
`.omp`, `.pi`, `.pi-lens`, `.agents`, `.config/caveman`). On Linux, `enable_mail` covers the mail
clients (himalaya, meli) and the sieve filters; minimal turns it off.
Re-running `chezmoi init` keeps the stored profile; to pick another, edit `install_profile`.

The shell, PowerShell profile and functions, mise, GnuPG and SSH have no toggle: the rest of
the setup needs them. A module added to the repository stays on for an existing machine until
`chezmoi init` asks about it; run `chezmoi init` after updating to answer.

chezmoi runs scripts automatically in this order:

**Phase 1 — before files (run_once / run_onchange, by numeric prefix):**

**Windows:**

| Script | What it does |
|--------|--------------|
| `run_once_00_windows-install` | Bootstrap (Scoop, fzf, mise, Dev Mode) + interactive package install (winget, scoop, PowerShell modules) + the choice of mise tools: full offers every tool that runs on Windows, minimal only the desktop apps (those in `shortcuts.json`); the rest go to the user variable `MISE_DISABLE_TOOLS`, so mise ignores them from then on |
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
| `run_onchange_after_08_windows-mise-integration` | Runs `mise install` (minus `MISE_DISABLE_TOOLS`), adds the mise shims to the user `PATH` and creates Start Menu shortcuts for the portable mise apps in `packages/windows/system/shortcuts.json` (re-runs when `mise.lock` or `config.toml` changes) |

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
