# Linux configuration

## Stack

NixOS + Hyprland (Wayland compositor) + Dank Material Shell (DMS).

NixOS/Home Manager is the declarative source of truth for the Linux system,
packages, services, hardware, Hyprland, and DMS. Chezmoi is only for personal
dotfiles, templates, and scripts that are not managed by Nix. Never let both
repositories manage the same file.

This repository no longer bootstraps Linux packages. Pacman/AUR package lists
and the Arch/CachyOS installation script were removed. Package installation
belongs in the [NixOS configuration](https://github.com/Villoh/nixos-config).

See also: [NixOS](nixos/README.md) (current target) and [Omarchy](omarchy/README.md) (reference).

## dot_config — key apps

| Path | Description |
| ------ | ------------- |
| `hypr/hyprland.conf` | Hyprland main config. Includes: `animations.conf`, `keybindings.conf`, `monitors.conf`, `windowrules.conf`, `userprefs.conf`, `shaders.conf`, `pyprland.toml` |
| `hypr/hypridle.conf` | Hypridle idle daemon config |
| `hypr/hyprlock/` | Hyprlock screen locker. `catppuccin/` and `vivek-hyprlock-styles/` are git submodules |
| `waybar/` | Waybar status bar config and CSS |
| `swaync/` | SwayNC notification center |
| `swayosd/` | OSD overlays (volume, brightness) |
| `kitty/` | Kitty terminal |
| `ghostty/` | Ghostty terminal |
| `dot_tmux.conf.tmpl` | Tmux multiplexer (`~/.tmux.conf`) |
| `zsh/` | Zsh-specific functions, aliases, and completions |
| `cliphist/` | Cliphist clipboard history |
| `nchat/` | Terminal chat client |
| `FreeTube/` | FreeTube YouTube frontend (settings are `.db`, gitignored) |
| `cava/` | Audio visualizer |
| `btop/` | Resource monitor |
| `yazi/` | File manager. `plugins/` and `flavors/` are gitignored — install with `ya pack` |

## dot_local/bin — scripts

All scripts use `$(chezmoi source-path)` instead of hardcoded paths.

| Script | Description |
| -------- | ------------- |
| `dotfiles-sync` | Sync: `chezmoi re-add` + git add/commit/push |
| `backup-packages` | Export user-level package/tool lists to `packages/linux/` |
| `restore-packages` | Reinstall supported user-level tools from `packages/linux/` lists |
| `backup-zsh` | Save Zsh and plugin packages for Arch/Omarchy sync |
| `restore-zsh` | Reinstall saved Zsh and plugin packages on Arch/Omarchy |
| `list-packages` | List currently installed packages (legacy Arch-oriented helper; review before use on NixOS) |
| `secrets` | Manual secret refresh with `fzf`, backed by `packages/linux/system/secrets.json` |
| `bwp` | Bitwarden Plus CLI helpers with shell-independent runtime session |
| `web-search` | Search DDG, Google, Brave, Wikipedia, GitHub, Stack Overflow, or Arch Wiki with `w3m` |
| `docker-service` | Start, stop, or inspect Docker systemd service |
| `extract-claude-config` | Export Claude config docs to `other_config/claude/` |
| `cleanup` | System cleanup (cache, logs, orphan packages) |
| `prune` | Gum-interactive cache cleanup for npm/pnpm/bun/uv/go/dotnet/docker |
| `update-packages` | Interactive updater for user-level tools; do not use it to replace NixOS updates |
| `plymouth-themes` | Install/switch Plymouth boot themes from `other_config/plymouth/themes/` |
| `sddm-themes` | Install/switch SDDM login themes from `other_config/sddm/themes/` |
| `fontman` | Font manager helper |
| `migrate-aur` / `migrate-flatpak` | Legacy Arch/Flatpak migration helpers; not part of the NixOS workflow |
| `post-hyde-install` / `pre-hyde-install` | HyDE desktop environment install hooks |
| `openvpn-*` / `ikev2-*` | VPN management |

## uv tools

`backup-packages --uv` saves package names, extras, and Python major/minor
versions to `packages/linux/uv-tools.txt`, using native `uv tool list
--show-extras --show-python` metadata. For example:

```text
harlequin[mysql] --python 3.13
```

`restore-packages --uv` validates the inventory and passes the package and
Python request as separate arguments to `uv tool install`, without `eval`.
Native uv installation handles already-installed tools, including changes to
extras and Python. Old name-only lists still work. Nonzero query exits or
invalid output keep the previous backup. Warnings alone do not: uv can skip
broken tools with exit 0, producing an incomplete or empty inventory. Check
warnings before accepting a backup. This is not a lockfile: package versions, dependency
versions, additional `--with` requirements, custom sources/indexes, and Python
patch versions are not preserved. Only restore trusted packages.

## mise tools

mise is restored from global/project configuration, not a generated package
inventory. Keep `config.toml` and project `mise.toml` files versioned, including
tool versions/options, custom plugin sources, environment variables, and tasks.
After restoring trusted configuration and installing mise/required plugins:

```bash
mise install
```

`backup-packages` and `restore-packages` no longer handle mise. Historical
`mise-tools.txt` inventories and their `.bak` files are left untouched and are
not used for restoration. NixOS/Home Manager still owns system packages.

`update-packages --mise` (also `mise` without the flag prefix) runs `mise upgrade`
for tools in the current configuration, respecting version ranges without
`--bump`. mise appears in the interactive menu and `--all` when installed.
The mise executable itself must be updated through NixOS or its package manager.

Linux user CLI configuration lives in `dot_config/mise/config.toml` and is
excluded on Windows. `npm:` tools use the Nix-provided standalone aube CLI
(`npm.package_manager = "aube_cli"`); Python tools use uv through `pipx:`.
Nix still provides Node, uv, and pnpm. Bun is declared in mise for tools such
as ocx. Zsh activates mise, and the login profile exposes shims to desktop apps;
pnpm's former global bin directory is no longer added to PATH.

Prefer mise registry names only when they resolve to the same tool and version.
Vercel uses `vercel` (registry backend `npm:vercel`), preserving its esbuild
approval; Bun already uses its core registry entry. Explicit sources remain
for tools without equivalent registry entries. Do not replace `npm:cf` with
`cf` (Cloud Foundry, not Cloudflare), OpenCode v2 with the registry's v1 route,
or `npm:@playwright/cli` with `playwright` (a different npm package).

Claude, Codex, Pi, and OMP use native binaries from their mise registry entries
(`claude`, `codex`, `pi`, `oh-my-pi`). Happy uses `npm:happy`, the upstream rename
of `happy-coder`; only its reviewed binary-unpacking postinstall is allowed.
Devin uses `http:devin` with the official Linux x86_64 archive and a pinned
SHA256 from its versioned manifest. Version discovery uses the upstream current
manifest, but a Devin bump also requires refreshing the checksum from
`https://static.devin.ai/cli/<version>/manifest.json`; stale checksums fail closed.
Nix CLI copies remain as fallback until explicitly retired. Herdr, Devin
Desktop, and auxiliary tools remain in Nix. Project Java is not declared in the
global mise configuration; do not upgrade inactive tools or prune it as part
of global maintenance. New shells select mise agents; existing Pi sessions
keep running their original executable.

Migrated root package versions are pinned. Ordinary `mise upgrade` respects
those pins; use `mise upgrade --bump` deliberately to update versions in the
configuration. Headroom/Serena update shortcuts use `--bump`, preserving their
tool options. Headroom keeps the ast-grep-cli exclusions in `uvx_args`.
Python requests and extras are also declared per tool, rather than inferred
from package names. Root pins are not transitive dependency lockfiles.

Install scripts are allowed only for selected native components. CCS and ASM
root hooks remain disabled to avoid modifying user configuration during
installation. Reviewed low-download tools have individual `aube_args`
exceptions; no global download-threshold bypass is configured. Preserve these
options in versioned mise configuration. The retired pnpm inventory must not be
used to reinstall the migrated tools as duplicate globals.

## Zsh plugin sync

`backup-zsh` and `restore-zsh` are intentionally separate from the general
package scripts. They sync only `zsh`, `omarchy-zsh`, and `zsh-*` plugin
packages between Arch/Omarchy systems:

```bash
backup-zsh
# commit/push packages/linux/zsh/
chezmoi update && chezmoi apply
restore-zsh
```

They require `pacman`; NixOS/Home Manager owns Zsh packages on NixOS.

## Omarchy plugin inventory

On machines using Omarchy, `backup-packages --omarchy` exports installed user
plugin Git origins to `packages/linux/omarchy-plugins.txt`. Omarchy is also an
option in the interactive backup menu and included in the default backup run.
The list is reference data, already excluded from deployment by `.chezmoiignore`.

On another machine with Omarchy and its shell already running, run
`restore-packages` and select **omarchy**, then choose the repositories to restore.
Existing origins are skipped; missing plugins use `omarchy plugin add`, retaining
Omarchy's validation, trust confirmation, and activation/placement prompts.
Only restore repositories you trust: plugins run unsandboxed in the shell.

This restores repositories at their current default branch, not pinned versions,
plugin dependencies, `shell.json` settings, or local edits. Backup warns about
modified repositories and skips non-Git custom plugins with a warning; preserve
those separately. No automatic installation is attached to `chezmoi apply`.

## Herdr plugin inventory

`backup-packages --herdr` exports `herdr plugin list --json` into
`packages/linux/herdr-plugins.json`. Windows uses a separate inventory at
`packages/windows/herdr-plugins.json`. Herdr is also included in the interactive
backup menu and default backup run. This requires a reachable Herdr session;
query/parse failures leave the previous inventory untouched.

The inventory stores plugin IDs, enabled state, GitHub `owner/repo[/subdir]`,
and local paths relative to `$HOME`. Backups omit requested refs and resolved
commits, so missing plugins restore from the repository's default branch. Local
plugins outside `$HOME` fail backup rather than exporting machine-specific
absolute paths. Herdr's generated `plugins.json`, checkouts,
binaries, credentials, and plugin-specific settings are not copied.

Run `restore-packages --herdr` to skip manager/location menus, then choose
plugins. Manager flags can be combined, e.g. `restore-packages --herdr --npm`;
without flags, the interactive manager menu remains. Supported flags: `--pacman`,
`--aur`, `--flatpak`, `--brew`, `--uv`, `--bun`, `--npm`, `--pnpm`, `--bin`,
`--cargo`, `--omarchy`, and `--herdr`. Existing IDs are left untouched
(including version and enabled state); registry warnings stop restoration for
that plugin. Missing GitHub plugins use `herdr plugin install`
without a ref and retain native trust/build confirmation. Herdr installs GitHub
plugins enabled; saved disabled plugins are disabled immediately afterward, so
startup code may run before that disable. Install only trusted plugins.

Local plugins require their package/working tree to exist first. For example,
restore the Pi package providing `pi-workflows` before linking it. After a trust
confirmation, restoration runs `herdr plugin link` with the saved enabled state.
Missing local manifests stop restoration with an error. Dependencies and build
toolchains must already be installed; no automatic setup runs on `chezmoi apply`.

The inventory is covered by the existing `packages/**` deployment exclusion
in `.chezmoiignore`.

## Shell configs

| File | Shell |
| ------ | ------- |
| `dot_profile` | POSIX |
| `dot_zshrc` | Portable Zsh behavior and Omarchy integration |

`dot_zprofile` still sources `~/.profile`; Home Manager owns the NixOS-only
plugin bootstrap while `dot_zshrc` owns portable shell behavior.

## Reference-only (other_config)

Not deployed by chezmoi — installed manually via scripts.

| Path | Description |
| ------ | ------------- |
| `other_config/plymouth/themes/` | Boot splash themes (4 submodules). Managed by `plymouth-themes` script |
| `other_config/sddm/themes/` | SDDM login themes (1 submodule). Managed by `sddm-themes` script |
| `other_config/system/` | Legacy/reference system configuration; NixOS owns the active system configuration |
| `other_config/system/sdboot/` | Systemd-boot config reference |
| `other_config/linux-cachyos-pollrate.toml` | USB polling rate config |
