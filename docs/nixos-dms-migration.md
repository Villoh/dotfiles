# NixOS + DMS

This is the current Linux target: NixOS as the operating system,
[Hyprland](https://hyprland.org/) as the compositor, and
[Dank Material Shell](https://danklinux.com) (DMS) as the desktop shell.

The NixOS repository is the declarative source of truth for the system,
packages, services, hardware, Hyprland, and DMS. This chezmoi repository is a
complement: it manages personal dotfiles and scripts that are not managed by
Nix/Home Manager. Do not apply overlapping configuration from both systems.

The historical CachyOS/Omarchy sections below are retained as migration notes,
not as installation instructions for this chezmoi repository.

## ISO + flashing

- Download: [nixos.org/download](https://nixos.org/download/) — **Graphical
  ISO** (has a live desktop + graphical installer; convenient even though
  DMS/Hyprland will replace whatever DE it boots into) vs **Minimal ISO**
  (console only, manual partitioning). Graphical unless comfortable doing
  the whole install from a TTY.
- Flash with **balenaEtcher** — same tool already validated for the Omarchy
  USB (MIKELUSB8), no reason to switch to Rufus.

## Dual boot with Windows

Same physical layout as the Omarchy plan: Disco 0 (wipe target for NixOS),
Disco 1 (Windows/AtlasOS, untouched, its own separate ESP). Because the two
ESPs live on **different disks**, this hits the same cross-disk situation
Omarchy's Limine setup does — the fix differs by bootloader choice:

- **systemd-boot (NixOS default)** — only auto-detects Windows when its
  `bootmgfw.efi` lives on the *same* ESP systemd-boot is installed to
  ([confirmed on the NixOS wiki](https://wiki.nixos.org/wiki/Windows), and
  [ArchWiki](https://wiki.archlinux.org/title/Systemd-boot): systemd-boot
  can only launch EFI binaries from the ESP it's installed to, or an
  XBOOTLDR partition on the *same disk*). Real fix, not just a firmware
  keypress: copy Windows' own `\EFI\Microsoft` folder onto the NixOS ESP,
  then add a manual entry:

  ```sh
  mkdir -p /boot/EFI/Microsoft
  cp -r /mnt/windows-esp/EFI/Microsoft/* /boot/EFI/Microsoft/
  cat > /boot/loader/entries/windows.conf <<'EOF'
  title   Windows
  efi     /EFI/Microsoft/Boot/bootmgfw.efi
  EOF
  ```

  Works because `bootmgfw.efi` locates its BCD/`winload.efi` via the
  Windows partition's GUID, not the ESP's path — a plain file copy is
  enough ([community-confirmed](https://forum.endeavouros.com/t/tutorial-add-a-systemd-boot-loader-menu-entry-for-a-windows-installation-using-a-separate-esp-partition/37431)).
  NixOS's systemd-boot activation only ever touches its own
  `nixos-generation-*.conf` entries, so `windows.conf` survives every
  `nixos-rebuild switch` untouched. Only maintenance cost: re-copy if a
  major Windows feature update ever replaces `bootmgfw.efi` (rare, and no
  worse than os-prober needing a re-run below). Firmware F11/F12 stays as
  the zero-effort fallback if this manual step is skipped.
- **GRUB + os-prober** — the actual equivalent of Limine's `limine-scan`:
  scans all disks at every rebuild and adds a real "Windows Boot Manager"
  entry to GRUB's own menu automatically.

  ```nix
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";   # EFI, not MBR
  boot.loader.grub.useOSProber = true;
  ```

  Trade-off: NixOS's installer defaults to systemd-boot, so this is a
  deliberate switch away from it; os-prober's result is baked in at
  `nixos-rebuild switch` time, so it needs a re-run if Windows' own
  bootloader ever changes.
- **Fast Boot gotcha** — identical issue already documented in
  `docs/omarchy-migration.md`: this is a UEFI *firmware* behavior, not
  distro-specific. If Windows shows in a boot menu but won't actually
  boot, disable **Fast Boot** in the UEFI firmware (separate from
  Windows' own Fast Startup, already off).

Recommendation: **systemd-boot + the manual Windows entry above**. Real
menu entry, no F11/F12, no second bootloader added to the stack, and
stays fully compatible with Lanzaboote/Secure Boot if that's ever pursued
(Lanzaboote replaces systemd-boot specifically — GRUB has no equally
well-trodden Lanzaboote path). GRUB + os-prober is the fallback only if
the manual copy step is a maintenance burden not worth carrying (e.g.
Windows reinstalled/repaired often enough that `bootmgfw.efi` needs
re-copying repeatedly).

## Secure Boot (optional, post-install)

Not required, same "leave Windows for when I'm forced" framing as the
Omarchy doc's Secure Boot section. If pursued, NixOS's answer is
[Lanzaboote](https://github.com/nix-community/lanzaboote) — an actively
maintained module, unlike Omarchy's explicitly-unsupported DIY `sbctl`
path (see the gap study above). It still uses `sbctl` for the actual key
handling, same tool Omarchy's own optional path uses:

```sh
sudo sbctl create-keys                      # generates keys in /var/lib/sbctl
```

```nix
# flake.nix — add as an input
lanzaboote.url = "github:nix-community/lanzaboote/v1.1.0";

# configuration.nix
imports = [ lanzaboote.nixosModules.lanzaboote ];
environment.systemPackages = [ pkgs.sbctl ];
# Lanzaboote replaces the systemd-boot module — must be forced off.
boot.loader.systemd-boot.enable = lib.mkForce false;
boot.lanzaboote = {
  enable = true;
  pkiBundle = "/var/lib/sbctl";
};
```

`nixos-rebuild switch`, then `sudo sbctl verify` to confirm the generated
boot files are signed. Put the firmware into Secure Boot *Setup Mode*
(steps are vendor-specific — ThinkPad/Framework/Surface/ASUS all differ,
see [Lanzaboote's enable-secure-boot guide](https://nix-community.github.io/lanzaboote/getting-started/enable-secure-boot.html)),
boot back in, then enroll keys **keeping Microsoft's** so Windows still
boots under Secure Boot — the direct equivalent of Omarchy's
`sbctl enroll-keys -m`:

```sh
sudo sbctl enroll-keys --microsoft
```

Reboot, confirm with `bootctl status` (`Secure Boot: enabled (user)`).
Unlike Omarchy's pacman hook that re-signs the kernel on every
`omarchy-update`, Lanzaboote signs automatically as part of every
`nixos-rebuild switch` — no separate hook to maintain.

**Interaction with the dual-boot choice above:** Lanzaboote's documented
path explicitly replaces the *systemd-boot* module — there's no equally
well-trodden GRUB+Lanzaboote combo. So Secure Boot + a real GRUB dropdown
menu together isn't the well-supported path; if Secure Boot is ever
pursued, pair it with systemd-boot + firmware F11/F12 for Windows, not
GRUB+os-prober.

## Installing DMS

- Needs **NixOS 26.05 stable or newer** (DMS landed in nixpkgs stable at
  26.05). Native module, no flakes required:

  ```nix
  # configuration.nix
  programs.dms-shell.enable = true;
  ```

  `nixos-rebuild switch` and it's installed with sane defaults.
- Flake-based install only needed for home-manager-per-user setups, faster
  updates than nixpkgs, or building from source — skip unless one of those
  applies.

## Hyprland vs Niri

DMS ships dedicated per-compositor integration (keybinds, layer-shell
rules, gaps/radius) for niri, Hyprland, Sway, MangoWC, labwc, Miracle WM —
it isn't tied to one.

- **Hyprland** — what the existing `dot_config/hypr/` keybindings and the
  Omarchy prep already assume. Lowest-friction choice, most muscle memory
  and scripts (`dot_local/bin/screenshot*`, `cliphist.sh`) carry over
  unchanged.
- **Niri** — scrollable-tiling, KDL config, closest to DMS's own design
  language, but a second window-management model to relearn on top of the
  shell itself.

**Decided: Hyprland.** Niri's scrollable-tiling loses track of open windows
for focus/concentration — the exact opposite of what a window manager
should help with. Also lowest-friction pick given the existing
`dot_config/hypr/` keybindings and Omarchy prep.

## Gap study — actually diffed both repos

First pass of this doc guessed at DMS's scope from a marketing page. This
pass cloned `basecamp/omarchy` (439 scripts in `bin/`, `manual/` with 51
chapters) and `AvengeMedia/DankMaterialShell` (`quickshell/Services/` — 65
QML services, `quickshell/Modules/` — 20 UI modules, `core/cmd/dms/` — the
`dms` CLI) and diffed feature-by-feature. DMS covers far more than the
first draft credited it for; the real gaps are narrower and mostly outside
the shell's scope entirely.

### A. Already covered by DMS — first draft was wrong here

| Feature | DMS source |
| --- | --- |
| Clipboard history (incl. images) | `ClipboardService.qml`, `dms commands_clipboard` |
| Screenshot / region capture | `dms commands_screenshot` |
| Color picker | `ColorPicker/`, `dms commands_colorpicker` |
| Network, Bluetooth, VPN, Tailscale | `NetworkService`, `BluetoothService`, `VPNService`, `TailscaleService` — all in Control Center |
| Printing | `CupsService.qml` |
| Calendar (local, khal, Google/MS/CalDAV via `dankcalendar`) | `CalendarService`, `CalendarDankBackend`, `CalendarKhalBackend` |
| Notifications + changelog surfacing | `NotificationService`, `ChangelogService` |
| Scratchpad notes, dock, process list | `Notepad/`, `Dock/`, `ProcessList/` modules |
| Login screen | separate `dank-greeter` (greetd) project, settings front-end built into DMS |
| Wallpaper-driven system theming (GTK/Qt/terminals/editors) | `matugen` + `dank16`, auto-generated per wallpaper — no manual per-theme app wiring needed, unlike Omarchy's `omarchy-theme-set-*` |
| Plugin ecosystem | [plugins.danklinux.com](https://plugins.danklinux.com) registry + `dms plugins` CLI, lockfile-pinned |

### B. Real shell-level gaps — DMS has no equivalent, any distro

| Omarchy feature | Evidence | Notes |
| --- | --- | --- |
| AI dictation (Voxtype: hold F9 / `Super+Ctrl+X`) | `manual/11`, `bin/omarchy-voxtype-*` (5 scripts) | No DMS service does speech-to-text |
| OCR text extraction (`Super+Ctrl+PrtScr` → tesseract → clipboard) | `manual/11` | No DMS equivalent; would need a hand-wired `grim`+`slurp`+`tesseract` keybind |
| System-wide font switcher (`omarchy-font-current/list/set`) | `bin/omarchy-font-*` | No `dms font` command found |
| Named-app curated skins (Obsidian, VS Code, Claude Code CLI, GNOME, tmux, ASUS ROG / Framework16 keyboard RGB) beyond generic GTK/Qt/terminal | `bin/omarchy-theme-set-{obsidian,vscode,claude,gnome,tmux,keyboard-asus-rog,keyboard-f16}` | matugen/dank16 theme *categories* of apps automatically; Omarchy also hand-wires specific named apps DMS doesn't know about |

### C. Distro/app-curation gaps — not DMS's job, must be built into the Nix config

Omarchy is a whole distro; DMS is only the shell layer of one. These are
features of *Omarchy the distro*, not of Hyprland+bar-and-launcher, so
comparing them to DMS is apples-to-oranges — but they're still work that
has to land somewhere in the NixOS config to reach parity:

| Omarchy feature | Evidence | NixOS-side equivalent |
| --- | --- | --- |
| One-menu install/remove catalog (33 installers / 26 removers: gaming platforms, editors, VPNs, 1Password, Dropbox, Spotify, Sunshine, Signal, dev-env, Docker DBs…) | `bin/omarchy-install-*`, `bin/omarchy-remove-*` | Hand-build the package list in `configuration.nix` / home-manager — one-time cost, then declarative |
| PWA web-app installer (HEY, Zoom, WhatsApp, YouTube, Basecamp, etc. as `.desktop` entries via browser app-mode) | `bin/omarchy-webapp-*`, `applications/*.desktop` | **Solved** — [PWAsForFirefox](https://github.com/filips123/PWAsForFirefox) (`firefoxpwa`), see solutions table below |
| Hardware-quirk scripts (27: ASUS ROG/ExpertBook/Zenbook, Dell XPS OLED/haptic-touchpad, Framework16, Surface, NVIDIA GSP/hybrid-GPU, Intel PTL/SOF, fingerprint, touchscreen) | `bin/omarchy-hw-*` | [`nixos-hardware`](https://github.com/NixOS/nixos-hardware) flake input covers some devices — verify per-machine, coverage isn't guaranteed |
| AI coding-agent usage tracking (Claude Code / Codex / Fireworks bar widget, crash-watch) | `bin/omarchy-agent-*` (7 scripts) | Partially solvable — see solutions table below, no ready-made DMS plugin exists yet |
| Retro gaming cores/install | `bin/omarchy-games-retro-*`, `manual/26` | Package list item, not shell-related |
| Root filesystem snapshot on every update, restore from Limine boot menu | `bin/omarchy-snapshot`, `manual/47` — **Limine-only**, not available on GRUB/systemd-boot | See section D — NixOS generations solve the same problem differently |

### D. Where NixOS is arguably ahead of Omarchy — not a gap to fill

- **Declarative provisioning.** Omarchy hand-rolls reproducibility with
  `omarchy-provision-*`, `omarchy-state`, and a `migrations` system (see
  `agents/skills/migrations.md` in its repo) to keep installs consistent
  across updates. `configuration.nix` / a flake gives that for free.
- **Rollback.** Omarchy's snapshot restore only works on Limine, reverts
  root but not `/home`, and needs a manual boot-menu selection. NixOS
  generations (`nixos-rebuild switch --rollback`, or just picking an older
  generation at boot) roll back the *entire declared system* atomically,
  no btrfs/Limine dependency — narrower scope (config only, not arbitrary
  file changes) but strictly more reliable for "the last rebuild broke
  something."
- **Updates.** `omarchy-update` updates the distro; DMS updates itself
  separately. `nixos-rebuild switch` / `nix flake update` updates OS +
  DMS module + every package in one atomic step.

## Filling the gaps — solutions research

Actual research pass (not guesses) for the 13 categories that matter most,
finding concrete, currently-maintained tooling for each:

| Gap | Solution found | Notes |
| --- | --- | --- |
| Boot/install provisioning | [disko](https://github.com/nix-community/disko) + [nixos-anywhere](https://github.com/nix-community/nixos-anywhere) | Declarative disk layout + unattended install over SSH/kexec in one flake-driven command — replaces Omarchy's installer *and* its `omarchy-provision-*`/`omarchy-state`/migrations pile |
| Hardware quirks | [NixOS/nixos-hardware](https://github.com/NixOS/nixos-hardware) flake | Per-model modules confirmed for Framework 13, ASUS ROG Zephyrus, some Dell XPS lines — add as a flake input, pull in `nixosModules.<model>`; verify the exact model exists before relying on it |
| Security defaults | **Decided:** [lanzaboote](https://github.com/nix-community/lanzaboote) (Secure Boot) + NixOS security baseline (`networking.firewall.enable` — on by default, `services.fail2ban`, `security.apparmor.enable`, `security.sudo` hardening) | **NixOS is ahead here** — Lanzaboote is an actively maintained community Secure Boot project; Omarchy's own manual admits it has *no official Secure Boot support*, DIY `sbctl` only |
| Gaming presets | Native `programs.steam.enable` / `programs.gamescope.enable` + MangoHud (nixpkgs) + [play.nix](https://github.com/TophC7/play.nix) for declarative Gamescope wrapper presets | Covers the intent of `omarchy-install-gaming-*` declaratively instead of as one-off installer scripts |
| Development presets | [devenv](https://devenv.sh) or `direnv` + `nix-direnv` | Per-project reproducible shells — the standard Nix idiom, strictly more reproducible than `omarchy-install-dev-env` |
| Curated app installers | **Decided:** a single declarative `apps.nix` (package list, this repo's source of truth) + DMS's Launcher plugin wired to it as an optional friendlier front-end | Rejected `nix-software-center`/`nh` as the primary path — they're browse/search tools, not a source of truth. `apps.nix` *is* Omarchy's install catalog, just declarative; the DMS Launcher plugin (section above) is UI sugar over the same file, not a replacement for it |
| Web-app manager | [PWAsForFirefox](https://github.com/filips123/PWAsForFirefox) (`firefoxpwa`) | Actively maintained, Firefox extension + native `firefoxpwa` CLI, installs real `.desktop` entries — direct drop-in for `omarchy-webapp-*` |
| Windows VM workflow | [quickemu](https://github.com/quickemu-project/quickemu) (packaged in nixpkgs) for a plain VM; VFIO + Looking Glass for GPU passthrough | `quickemu` auto-configures TPM/Secure Boot for a Windows 11 guest out of the box; passthrough is documented for NixOS specifically but is a much more involved, separate setup |
| Tailscale integration | `services.tailscale.enable = true;` (native NixOS module) + DMS's own `TailscaleService` | Already solved twice over — no third-party tooling needed at all |
| Capture/OCR/recording | Screenshot: DMS's `dms commands_screenshot` (native, section A). OCR + QR: [NormCap](https://github.com/dynobo/normcap) | NormCap replaces *both* Omarchy's tesseract OCR shortcut and `omarchy-capture-qr` in one actively maintained app (Flathub/nixpkgs) — recording tool not verified this pass |
| AI/coding-agent integration | [ccusage](https://ccusage.com) (multi-CLI usage engine: Claude Code, Codex, Copilot CLI, Gemini CLI, more) + [waybar-claude-code](https://shyft.ai/skills/waybar-claude-code) as a proof-of-concept bar wrapper | No ready-made DMS plugin found — `waybar-claude-code` proves the wrapper pattern exists for Waybar; porting it to a DMS widget plugin (template exists, see below) is DIY work |
| Unified OS menu | DMS's own **Launcher plugin type** (`.agents/skills/dms-plugin-dev/assets/templates/launcher/{Launcher.qml,Settings.qml,plugin.json}` in the DMS repo) | Documented, first-class extension point for building an Omarchy-Menu-style action launcher (Install/Setup/Theme submenus) directly inside DMS's own Spotlight search, instead of a bolted-on wofi/rofi menu |
| System-wide keybind philosophy | DMS's embedded per-compositor keybind sets (`core/internal/config/embedded/hypr-binds.lua`, `niri-binds.kdl`) + an explicit user-override layer (`hypr-binds-user.lua`) shipped alongside them | DMS already provides opinionated defaults plus a designated override point, and it's compositor-native (works the same shape on Niri) unlike Omarchy's Hyprland-only keybind scheme |

Still unverified / needs a hands-on pass once hardware is picked: exact
`nixos-hardware` module match for the target laptop, a concrete Wayland
screen-recording package, and whether building the AI-usage DMS plugin is
worth the effort vs. just running `waybar-claude-code` alongside DMS.

## What already carries over from the Omarchy prep

- `dot_config/hypr/**` keybindings — portable as-is if Hyprland is chosen.
- `dot_local/bin/*` scripts (screenshot, cliphist, git tooling) —
  compositor-agnostic; git tooling still needed, screenshot/clipboard are
  now optional since DMS's own `dms commands_screenshot`/`commands_clipboard`
  cover the same ground natively (section A above).
- GPG export/import step before wiping any disk — identical.
- balenaEtcher USB flashing workflow — identical.

## Open decisions

- [x] Hyprland vs Niri → Hyprland.
- [ ] Native `programs.dms-shell.enable` vs flake-based install.
- [ ] Whether this is pursued instead of, or after, the Omarchy install
      already in progress.
