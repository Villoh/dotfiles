# CachyOS → Omarchy migration

Tracking doc for retiring CachyOS and making Omarchy 4.0.0 (Quattro) the Linux
daily driver. Windows (AtlasOS) stays untouched on its own disk for the rare
forced case. Reference only — never deployed (see `.chezmoiignore`).

## Target machine facts

- Disco 0 (GIGABYTE GP-AG42TB, 2 TB, GPT) — current CachyOS: 2 GB ESP +
  ~1860 GB LUKS partition, effectively 100% allocated. **This is the wipe
  target** for a full-disk Omarchy install.
- Disco 1 (Kingston SNV3S1000G, 1 TB) — Windows (AtlasOS), untouched.
- Disco 3 (Realtek RTL9210B-CG, 1 TB) / Disco 4 (JMicron, 500 GB) — data
  drives (D:, E:), untouched, no free space either way.
- ISO: `omarchy-4.0.0.iso`, SHA256 `9224fab3720560f771969a99a499e5f7e0f8e2d6a0681d872d52f05fb5003da4`
  — verified against the v4.0.0 GitHub release, matches.
- USB: MIKELUSB8 (F:, SanDisk Cruzer Blade 7.8 GB) — flashed and validated
  with balenaEtcher, ready to boot.

## Install plan

- [x] Verify ISO hash against official release.
- [x] Flash + validate USB.
- [ ] **Export GPG key(s) before wiping CachyOS** — `dot_config/git/encrypted_local.asc`
      / `encrypted_work.asc` and the `secrets`/`bwp` scripts all decrypt
      through GPG; nothing decrypts on the fresh Omarchy install without it.
      ```
  gpg --list-secret-keys --keyid-format long   # find the key ID
      gpg --export-secret-keys --armor <KEYID> > gpg-secret-<KEYID>.asc
      gpg --export --armor <KEYID> > gpg-public-<KEYID>.asc
      gpg --export-ownertrust > gpg-ownertrust.txt
      ```
      Copy those 3 files somewhere off this disk (USB, other drive) — never
      into the chezmoi repo itself. On the fresh Omarchy install:
      `gpg --import gpg-secret-*.asc && gpg --import-ownertrust gpg-ownertrust.txt`.
- [ ] Boot USB, **full-disk install** on Disco 0 (no free-space install
      needed now that CachyOS is being wiped, not kept alongside).
- [ ] Secure Boot / TPM must be OFF in BIOS for the installer to run at all —
      Omarchy has no official Secure Boot support.
- [ ] Run `sudo limine-scan` after install so Windows Boot Manager (Disco 1
      ESP) shows up in Limine's own boot menu, not just the firmware's F11/F12
      menu. Verify with `limine-list`.
- [ ] Watch for the cross-disk gotcha (ArchWiki, confirmed applicable here):
      an entry pointing at a different disk than `limine.conf` can fail with
      `Failed to open image with path: ...` if firmware doesn't init all
      disks at boot (Fast Boot). If Windows shows in the menu but won't
      actually boot, disable **Fast Boot** in the UEFI firmware (separate
      from Windows' own Fast Startup, `powercfg /h off`, already done for
      CachyOS).
- [ ] Manual fallback if `limine-scan` doesn't find it — add to
      `/boot/limine.conf`:
      ```
  /Windows
          protocol: efi
          path: uuid(<PARTUUID-of-windows-ESP>):/EFI/Microsoft/Boot/bootmgfw.efi
      ```
      Get the PARTUUID from Linux with `lsblk -o NAME,PARTUUID,LABEL` on the
      Windows ESP (Disco 1, 200 MB System partition).
- [ ] Note: `omarchy-refresh-limine` overwrites `/boot/limine.conf` with
      Omarchy's default theme template and re-runs `limine-update` — it does
      NOT run automatically, but if it's ever used for theme troubleshooting,
      re-run `limine-scan` afterwards to get Windows back.

## Open decision: Secure Boot post-install (optional)

Not required, DIY only, not officially supported by Omarchy. If pursued:

```
sudo pacman -S sbctl
sudo sbctl create-keys
sudo sbctl enroll-keys -m   # -m keeps Microsoft keys so Windows still boots under SB
sudo sbctl sign -s /boot/EFI/BOOT/BOOTX64.EFI   # Limine
sudo sbctl sign -s /boot/vmlinuz-linux
```

`sbctl`'s pacman hook re-signs the kernel automatically on every
`omarchy-update`. Skip entirely if Secure Boot isn't actually needed for
anything — simplest and what "leave Windows for when I'm forced" implies.

## Dotfiles cleanup

### Done

- [x] Removed `dot_config/hypr.old/` entirely (was deployed to
      `~/.config/hypr.old`, read by nothing).
- [x] Moved the 3 keybind files worth keeping as reference
      (`keybindings.conf`, `windowrules.conf`, `userprefs.conf`) to
      `other_config/hypr-old-keybinds/` (reference-only, never deployed).
- [x] Deleted `hypr.old/hyprlock/` (theme files, unrelated to keybinds) and
      its 2 submodules (`catppuccin/hyprlock`, `vivek-hyprlock-styles`);
      `.gitmodules` cleaned.
- [x] Fixed stale `dot_config/hypr/` / `hypr.old` references left over from
      that move: `.chezmoiignore`, `.chezmoiscripts/run_once_00_linux-install.sh.tmpl`
      (was still cloning submodules that no longer exist), `docs/structure.md`,
      `README.md`.
- [x] Removed `other_config/plymouth/themes/cachyos` submodule — it's
      literally CachyOS's own boot splash, pointless once CachyOS is gone.
      Fixed the same 3 stale-reference spots
      (`.chezmoiscripts/run_once_00_linux-install.sh.tmpl`, `docs/structure.md`,
      `.gitmodules`).

### Pending — SDDM theme decision

- Confirmed Omarchy uses SDDM (`install/login/sddm.sh`), with its own
  "omarchy" theme and **autologin enabled by default**
  (`/etc/sddm.conf.d/autologin.conf`).
- [x] Fixed `dot_local/bin/sddm-themes`: `install_theme()` now writes the
  `Current=` override to a drop-in, `/etc/sddm.conf.d/zz-sddm-theme.conf`
  (sorts after Omarchy's `autologin.conf`, so it actually wins), instead of
  overwriting the whole `/etc/sddm.conf` (which lost the precedence fight
  and clobbered anything else in that file).
- [x] Added a menu option, "Switch to Omarchy default theme"
  (`use_omarchy_theme`), that just removes that drop-in — no reinstalling,
  falls straight back to Omarchy's own `Current=omarchy`.
- [x] Decided: leave `install_deps`/`enable_sddm` as-is. They re-do work
  Omarchy's installer already did (package install, `systemctl enable
  sddm.service`), but re-running them is harmless — not worth trimming.
- With autologin on, the SDDM screen is rarely seen anyway — factor that in
  before spending time fixing the script.

### Decided — Plymouth submodules kept, decision deferred on purpose

Confirmed Omarchy sets its own "omarchy" Plymouth theme
(`install/login/plymouth.sh`, always visible at boot regardless of
autologin). Remaining submodules (`adi1090x-themes`, `onepiece`,
`vortex-ubuntu`) are gusto calls, not overlap/dead-weight cases — kept as-is
so they're available to install after seeing Omarchy's default splash, in
case any of them is still preferred. Nothing to do here.

### Resolved — apps Omarchy's theme-set fought over

**Correction:** earlier version of this table over-counted. Omarchy's
`install/config/config.sh` does `cp -R ~/.local/share/omarchy/config/*
~/.config/` — a **one-time, install-time only** copy (covers `git`, `herdr`,
`starship.toml`, `tmux`, among others). It runs once during the OS
installer, before chezmoi is ever applied. Once chezmoi's symlinks land on
top of that afterward, Omarchy never touches those paths again — no ongoing
fight. Removed from this table.

The **real, recurring** conflict is only the apps `omarchy-theme-set`
actively regenerates on every `omarchy theme set <name>` — confirmed by
reading that script directly:

| App | Chezmoi path | Omarchy touches it via |
| --- | --- | --- |
| Alacritty | `dot_config/alacritty/*.toml` | `omarchy-restart-terminal` |
| btop | `dot_config/btop/themes/*` (~25 files) | `omarchy-restart-btop` |
| opencode | `dot_config/opencode/themes/*` | `omarchy-restart-opencode` |

Because chezmoi deploys these as symlinks into the source repo, a theme
switch doesn't just overwrite the live config — it writes straight through
the symlink into the chezmoi source files on disk, which would show up as
uncommitted drift in this repo.

**Bigger discovery on closer look**: `dot_config/alacritty/alacritty.toml`
and `dot_config/btop/btop.conf` turned out to already be **Windows-only
content**, not cross-platform — the alacritty file's own header says
"Alacritty - Windows Configuration" (`%APPDATA%\alacritty\`, `shell = pwsh`,
`winget install` instructions), and `btop.conf` is literally a **btop4win**
config with a hardcoded `C:\Users\mikel\scoop\apps\btop\...` theme path.
Neither would have worked on Linux at all, regardless of Omarchy. Their
theme files (`kanagawa-dragon.toml`, the ~25 btop `.theme` files) are
portable color data with no OS-specific paths, but only existed to feed
these two Windows-only main configs.

- [x] `dot_config/alacritty/**` and `dot_config/btop/**` (whole
      directories, main config + all theme files) → gated Windows-only in
      `.chezmoiignore`. Omarchy now owns both entirely on Linux via its own
      theme switcher; nothing of this repo's alacritty/btop content applied
      there anyway.
- [x] `dot_config/opencode/themes/**` → gated Windows-only too, but scoped
      to just that subfolder — the rest of `dot_config/opencode/`
      (`opencode.json`, `tui.jsonc`, `skills/`, `agents/`, `commands/`,
      `plugins/`) is real tool config unrelated to visual theming, still
      needed on Linux, left cross-platform.
- [x] Same discovery, found later in a follow-up pass: `dot_config/fastfetch/config.jsonc`
      also has a hardcoded Windows path
      (`"source": "C:/Users/Mikel/.config/fastfetch/ascii.txt"`) — broken on
      Linux regardless of Omarchy. Gated `dot_config/fastfetch/**`
      Windows-only too, dropped its `docs/linux.md` row.
- Validated live with `chezmoi ignored` + `execute-template` — nothing
  changes on this Windows machine, template still parses.

No overlap, leave as-is: cava, gh-dash, gitui, micro, yazi, zed, zellij,
ytm-player, wezterm, vesktop, nchat, FreeTube, git, herdr,
starship, tmux (one-time seed only, safe per above).

### Fixed — tmux XDG-path trap (worse than the one-time-seed apps)

Diffed both configs directly. **herdr**: no issue — Omarchy's shipped
`config/herdr/config.toml` is a much simpler generic default; ours
(`dot_config/herdr/config.toml.tmpl`) is the deliberate Zellij/tmux/herdr
parity scheme, and both land at the same path (`~/.config/herdr/config.toml`),
so chezmoi's symlink cleanly wins. Nothing to change.

**tmux** had a real, worse problem: since tmux 3.1, tmux checks
`$XDG_CONFIG_HOME/tmux/tmux.conf` (`~/.config/tmux/tmux.conf`) **before**
falling back to `~/.tmux.conf` — first file found wins, no merge. Omarchy's
installer drops its own simple default at that exact higher-priority path.
Chezmoi only ever managed `~/.tmux.conf` (the fallback path), so Omarchy's
copy would sit at `~/.config/tmux/tmux.conf` forever and tmux would silently
load *that* instead of the real, elaborate config — not a one-time seed,
a permanent silent loss.

- [x] Superseded by the decision below: chose Omarchy's own tmux over the
      redirect shim, so the `dot_config/tmux/tmux.conf` `source-file`
      workaround was removed again.

### Decided — herdr and tmux are now Windows-only

Omarchy's simpler tmux/herdr defaults won out — good enough that they might
get carried back to Windows later instead. Both made Windows-only in
`.chezmoiignore`:

- `.config/herdr/**` — ignored whenever `.chezmoi.os != "windows"` (no
  `enable_herdr` toggle existed or was added, just a plain OS gate).
- `.tmux.conf` / `.tmux-keys` — ignored unless `.chezmoi.os == "windows"`
  (same `enable_tmux` toggle, now also OS-gated).
- Removed `dot_config/tmux/tmux.conf` (the `source-file ~/.tmux.conf`
  redirect from the previous entry) — pointless now, and would have broken
  tmux startup on Omarchy since `~/.tmux.conf` no longer gets deployed there
  either. Omarchy's own tmux/herdr configs are left completely untouched on
  Linux.

Validated live with `chezmoi ignored` (both configs still deploy on this
Windows machine; nothing else changed).

### Fixed — `dot_config/zsh` was mostly HyDE boilerplate

- [x] Deleted `plugin.zsh` and `prompt.zsh` outright — both start with
      `return 1` (HyDE's own "ignore this file unless you remove this line"
      guard), so everything below it in both files was unreachable dead
      code (a zinit tutorial and an unused starship-in-zsh snippet). No
      other file referenced either one.
- [x] Trimmed `dot_zshrc` to its only 2 live lines (SDKMAN init, bun
      completions) — the rest was ~40 lines of HyDE's commented-out alias
      suggestions and banner comments.
- [x] Trimmed `dot_zshenv` to just the functional `conf.d/*.zsh` loader
      loop — dropped the HyDE ASCII banner. The loop itself is currently a
      no-op (no `conf.d/` tracked in this repo) but harmless to keep as an
      extension point.
- Kept as-is (genuinely personal, not HyDE cruft): `user.zsh`
  (pokego/fastfetch greeting, fnm/asdf/uv/homebrew env, `clear-pip`
  function, aliases), `functions/*.zsh`, `completions/fzf.zsh`, and the
  root `dot_zshenv`/`dot_zprofile` (the `ZDOTDIR` redirect — needed
  regardless of distro, not HyDE-specific).

### Fixed — bash dropped entirely, `dot_profile` bug fixed

- [x] Deleted `dot_bashrc`, `dot_bash_profile`, `dot_bash_logout` and the
      `enable_bash` toggle entirely — not used interactively (only
      `.bashrc` had real content; `.bash_profile`/`.bash_logout` were
      near-empty stubs), everything lives in zsh. If bash ever gets invoked
      one-off, it falls back to Arch/Omarchy's own system default — fine
      for that.
- [x] Found and fixed a real bug this surfaced: `.profile` was gated under
      the now-removed `enable_bash` block, but it's actually consumed by
      the **zsh** login chain (`dot_zprofile` → `source ~/.profile` for
      `EDITOR`/`BROWSER`/`GPG_TTY`/etc.). Moved it into the `enable_zsh`
      block instead — leaving it bash-gated would have silently stopped
      deploying it once bash was disabled, breaking zsh's env vars with no
      error.
- [x] Both bash rc files had `. "$HOME/.local/share/../bin/env"` (uv's env script)
      sourced **unconditionally, no existence guard** — errors on every
      shell start if uv hasn't installed that file yet (e.g. right after a
      fresh install). Fixed to match the already-correct zsh version:
      `[[ -s "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"`.
      (Moot now that the files are deleted, but was fixed first.)
- [x] `dot_profile` had `TERMINAL=kitty` — kitty isn't in this repo anymore
      (see the tmux/theme-catalog findings). Changed to
      `TERMINAL=alacritty` per user confirmation.
- Root `dot_zshenv`/`dot_zprofile`: reviewed, nothing to change — already
  minimal and load-bearing (sets `ZDOTDIR`, without it the entire
  `dot_config/zsh/*` setup becomes unreachable) — kept.

### Decided — zsh dropped entirely too

On reflection (same "Omarchy's defaults are winning me over" logic as
herdr/tmux), scrapped zsh altogether rather than keep maintaining it:

- [x] Deleted `dot_config/zsh/**` whole (`user.zsh`, `dot_zshrc`,
      `dot_zshenv`, `functions/*.zsh`, `completions/fzf.zsh` — including the
      genuinely personal parts, not just the HyDE boilerplate trimmed
      earlier) and the root `dot_zshenv` (the `ZDOTDIR` redirect).
- [x] Cleaned up the now-dead references: `.chezmoiignore` (`.zshenv`,
      `.config/zsh/**` entries removed from the `enable_zsh` block),
      `docs/structure.md`, `docs/linux.md`, `README.md`,
      `.gitignore` (`dot_config/zsh/functions/api-keys.zsh`, a gitignored
      local-only file under a directory that no longer exists).
- **Left as-is, flagged only**: `dot_zprofile` and `dot_profile` (still real
  — `.profile` has generic env vars, not zsh-specific) stay under the
  `enable_zsh` toggle for now. `dot_zprofile` only exists to be read by zsh
  at login, so it's technically orphaned now too — not deleted since it
  wasn't explicitly asked for this round.
- Omarchy's own shell defaults (bash, per its installer) take over on
  Linux — nothing left in this repo to conflict with them.

### Deferred — stale docs, on purpose

`docs/linux.md` and the Linux stack table in `README.md` still describe the
old HyDE/Hyprland/Waybar/Kitty/Ghostty setup, most of which is already gone
from the repo. Not rewriting now: the final app roster depends on the
decisions above and on what Omarchy itself ends up managing, so a rewrite now
would just get rewritten again after the install. Rewrite both once Omarchy
is the confirmed daily driver and the theme-overlap decisions are made.

### Reviewed — PowerShell ↔ bash script parity

Went through every `Documents/PowerShell/Functions/*.ps1` against its
`dot_local/bin/*` counterpart. Most pair up fine as-is: `backup.ps1` ↔
`backup-packages`, `restore.ps1` ↔ `restore-packages`, `secrets.ps1` ↔
`secrets`, `chezmoi.ps1` ↔ `dotfiles-sync`, `upgrade.ps1`/`upgrade-harness.ps1`
↔ `update-packages`/`--harness`, `bitwarden.ps1` ↔ `bwp`, `claude.ps1` ↔
`install-claude-plugins`. `devmode.ps1`, `win-keys.ps1`, `windhawk.ps1`,
`wsl-arch-setup.ps1`, `startup.ps1` are genuinely Windows-only concepts
(registry, GlazeWM, Windhawk, WSL) — correctly have no Linux counterpart.

**3 real findings:**

- [x] **Functional regression from today's zsh deletion, fixed**: `npm.ps1`
      (`socket npm` wrapper) and `pip.ps1` (`clear-pip`) only existed on
      Windows after zsh's `user.zsh` (which had exact equivalents) was
      deleted. Ported both as standalone bash scripts in `dot_local/bin/`
      (`npm`, `clear-pip`) instead of shell aliases/functions — works
      regardless of which shell Omarchy ends up using, no rc-file dependency.
      `~/.local/bin` ahead of the real `npm` in PATH makes the wrapper take
      over the same way the old alias did.
- [x] **`dot_local/bin/migrate-to-cachyos` deleted** — confirmed dead on
      Omarchy: migrates packages *into* CachyOS's own optimized repos
      (`cachyos-v3/v4/extra/core`), which won't exist there. Whole purpose
      evaporates, not just the name. Removed the doc reference in
      `docs/linux.md` too.
- Lower priority, cosmetic only: `cleanup` ("Arch/CachyOS" in banner text,
  logic itself is generic pacman/Arch and still works), `migrate-aur` /
  `migrate-flatpak` (mention `cachyos` repo priority in output text — still
  functional, just won't ever match on Omarchy), `plymouth-themes` ("cachyos"
  as one example theme name in `--help` usage text).

**Follow-up cleanup, same pass**: also deleted `dot_local/bin/fit-launcher-update`,
`cliphist.sh`, `dontkillsteam.sh`, `screenshot.sh`, `screenshot-menu.sh` — only
referenced from the frozen `other_config/hypr-old-keybinds/keybindings.conf`
(reference-only, never deployed), no live callers. Also dropped a dead
`docs/linux.md` row for `hytale-launcher`, which never actually existed as a
file in the repo. **This section (PowerShell ↔ bash parity) is done.**

### Done — `dot_config/autostart/`, `mimeapps.list`, `dot_config/fastfetch/`

- [x] `dot_config/autostart/vesktop.desktop` deleted — redundant, Vesktop's
      own `settings.json` already has `"autoStartMinimized": true`.
- [x] `dot_config/mimeapps.list` deleted — Omarchy manages MIME/default-app
      associations itself.
- [x] `dot_config/fastfetch/` gated Windows-only — same bug class as
      alacritty/btop: `config.jsonc` hardcodes
      `"source": "C:/Users/Mikel/.config/fastfetch/ascii.txt"`, broken on
      Linux regardless of Omarchy.
- [x] `dot_config/systemd/user/backup-system-config.service` deleted (old,
      no longer wanted) + `enable_systemd` toggle removed entirely.

### Done — git config refactor

`dot_config/git/config`'s `[alias]` block was ~250 lines mixing short
shortcuts with fully inlined multi-line shell functions. Split into 3 piles:

- **Kept as aliases** (short, single git subcommand or one-liner — the
  "SPEED"/"LOGS"/undo/worktree/utility/revert sections): unchanged.
- **Deleted outright**: GitHub CLI passthroughs (`whoami`, `pr`, `issue`,
  `gist`, `browse`, `auth`, `org`, `project`, `release`, `repo`, `codespace`,
  `pr-info`, `pr-view`, `co-commit`, `init-github`, `code-review`, `publish`,
  `languages` — just use `gh` directly, no value added) and the gist-based
  alias-backup system (`aliases-gist`/`-export`/`-import`/`-docs`/`alist` —
  had a literal unfilled `YOUR_GIST_ID_HERE`, never actually worked).
- **Moved to real commands** (checked first whether `git-extras`/`git-absorb`
  covered any of these — `git-absorb` is in Arch's official `extra` repo,
  added to `packages/linux/pacman/pacman.txt`, and `git config` now notes
  preferring `git absorb --and-rebase` over the custom `fixup`; scoop
  availability for Windows was unverified so custom scripts cover it there
  too, no hard dependency either way): `old`, `conflict`/`cf`,
  `can-merge`/`cfm`, `continue`, `abort`, `prune-local`, `clean-merged`,
  `auto-prune`, `fixup`, `churn`, `rebranch`, `yank`, `backmerge`, `lines`,
  `sha`, `zip`, `diff-file-last-commit`, `exclude`, `include`, `tree`,
  `remote-default`, `remote-set` → `dot_local/bin/git-*` (Linux, real `git-X`
  executables, invoked as `git X` — git resolves external commands
  transparently, so `cf = conflict` in the alias block still works
  unchanged) + `Documents/PowerShell/Functions/git-workflow.ps1` (Windows,
  plain functions since git doesn't chase `.ps1` files for subcommand
  resolution — call these directly, not via `git <name>`).
- The 7-command LAN git server (`server-addr/start/kill/test/clone/join/logs`)
  consolidated into one script each side: `dot_local/bin/git-lan-serve`
  (`git lan-serve <verb>`) and `git-lan-serve.ps1` (Windows functions).
- All 23 bash scripts validated with `bash -n`, both `.ps1` files validated
  with the PowerShell parser, gitconfig re-parsed clean with
  `git config -f ... --list` (124 alias entries remain, down from the
  original ~250-line block).
- [x] Moved the 23 bash scripts into `dot_local/bin/git/` (subfolder, not
      loose in `dot_local/bin/`). Since git's external-command lookup only
      checks literal `$PATH` directories (not subdirectories), added
      `export PATH="$HOME/.local/bin/git:$PATH"` to `dot_profile` right
      after the existing uv env sourcing — otherwise `git <name>` would stop
      finding them. Executable bit (`100755`) confirmed preserved through
      the move.
