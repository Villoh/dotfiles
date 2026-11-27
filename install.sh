#!/usr/bin/env bash
# One-shot CLI bootstrap for Villoh/dotfiles on Linux. In any terminal:
#
#   curl -fsSL https://raw.githubusercontent.com/Villoh/dotfiles/main/install.sh | bash
#
# Follows docs/install/bootstrap.md: chezmoi init (its own prompts), the GPG
# key for the personal flow, the GPG/SSH agent files, a decryption check with
# chezmoi diff, and chezmoi apply. Missing prerequisites, as the GUI does
# (installer/prereqs.go): chezmoi's static build into ~/.local/bin without
# root; git and gnupg with sudo and the package manager (apt, dnf, pacman),
# or brew on atomic images. NixOS installs nothing: it prints the Home Manager
# lines to add (see AGENTS.md). Answers are read from /dev/tty, so it works
# piped from curl.
set -euo pipefail

repo=Villoh/dotfiles
# Pinned with installer/prereqs.go (TestPinsMatch checks they agree).
chezmoi_url=https://github.com/twpayne/chezmoi/releases/download/v2.74.2/chezmoi-linux-amd64-musl
chezmoi_sha256=cebbe027a4c9b420a9aa3e55356c4d084f6d4a2c5562d18922494316f5656e0e

step() { printf '\n\033[36m== %s\033[0m\n' "$1"; }
ok() { printf '  \033[32m[OK]\033[0m   %s\n' "$1"; }
skip() { printf '  \033[33m[SKIP]\033[0m %s\n' "$1"; }
fail() { printf '  \033[31m[FAIL]\033[0m %s\n' "$1" >&2; exit 1; }
ask() { local answer; read -r -p "  $1" answer </dev/tty; printf '%s' "$answer"; }

[ "$(id -u)" -ne 0 ] || fail "run it as your user, not root: it sets up your home directory"
[ -r /dev/tty ] || fail "no terminal to answer the prompts (/dev/tty)"

# -- 1. Bootstrap tools ------------------------------------------------------
step "Bootstrap tools"
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac
missing=()
for exe in git gpg chezmoi; do
  if command -v "$exe" >/dev/null 2>&1; then ok "$exe: $(command -v "$exe")"; else missing+=("$exe"); fi
done
has() { [[ " ${missing[*]} " == *" $1 "* ]]; }

if [ ${#missing[@]} -gt 0 ]; then
  pkgs=()
  for m in "${missing[@]}"; do pkgs+=("${m/#gpg/gnupg}"); done
  # NixOS is declarative: say what to add instead of installing.
  [ ! -e /etc/NIXOS ] || fail "missing: ${missing[*]}. Add them to your NixOS/Home Manager configuration and rebuild:
    home.packages = with pkgs; [ ${pkgs[*]} ];"

  if has chezmoi; then
    [ "$(uname -m)" = x86_64 ] || fail "chezmoi has no static build for $(uname -m): install it from https://www.chezmoi.io/install/"
    mkdir -p "$HOME/.local/bin"
    tmp=$(mktemp "$HOME/.local/bin/.chezmoi-XXXXXX")
    curl -fsSL -o "$tmp" "$chezmoi_url"
    echo "$chezmoi_sha256  $tmp" | sha256sum -c --quiet - || { rm -f "$tmp"; fail "chezmoi SHA-256 mismatch"; }
    chmod 755 "$tmp" && mv "$tmp" "$HOME/.local/bin/chezmoi"
    ok "chezmoi installed into ~/.local/bin (checked SHA-256)"
  fi

  sys=()
  for m in git gpg; do has "$m" && sys+=("$m"); done
  if [ ${#sys[@]} -gt 0 ]; then
    # shellcheck source=/dev/null # the system's, read for ID and ID_LIKE
    family=$(. /etc/os-release 2>/dev/null; echo " ${ID:-} ${ID_LIKE:-} ")
    names() { local out=() t; for t in "${sys[@]}"; do
      if [ "$t" = gpg ]; then out+=("$1"); else out+=("$t"); fi; done; echo "${out[@]}"; }
    if [ -e /run/ostree-booted ]; then
      command -v brew >/dev/null 2>&1 ||
        fail "this system's image is read-only: install Homebrew and run brew install $(names gnupg), or layer them with rpm-ostree install and reboot"
      # shellcheck disable=SC2046 # one word per package
      brew install $(names gnupg)
    else
      echo "  Installing $(names gnupg) with your package manager (sudo asks for your password)"
      # shellcheck disable=SC2046 # one word per package
      case "$family" in
        *" debian "* | *" ubuntu "*) sudo sh -c "apt-get update -q && apt-get install -y $(names gnupg)" ;;
        *" fedora "* | *" rhel "* | *" centos "*) sudo dnf install -y $(names gnupg2) ;;
        *" arch "*) sudo pacman -S --needed --noconfirm $(names gnupg) ;;
        *) fail "install $(names gnupg) with your package manager and run this again" ;;
      esac
    fi
  fi

  for exe in "${missing[@]}"; do
    command -v "$exe" >/dev/null 2>&1 || fail "$exe still not found after installing it"
    ok "$exe: $(command -v "$exe")"
  done
fi

# -- 2. Flow -----------------------------------------------------------------
step "Flow"
echo "  1) Personal:  decrypt the encrypted files with my GPG key"
echo "  2) Secondary: skip encrypted files (identities, work config, secrets)"
flow=""
until [ "$flow" = 1 ] || [ "$flow" = 2 ]; do flow=$(ask "Choose 1 or 2: "); done

# -- 3. chezmoi init (clones, asks the install profile and modules) ----------
step "chezmoi init"
chezmoi init "https://github.com/$repo" </dev/tty
src=$(chezmoi source-path)

exclude=()
if [ "$flow" = 1 ]; then
  # -- 4. GPG key -------------------------------------------------------------
  step "GPG key"
  recipient=$(sed -n 's/.*recipient = "\([^"]*\)".*/\1/p' "$src/.chezmoi.toml.tmpl" | head -n1)
  [ -n "$recipient" ] || fail ".chezmoi.toml.tmpl has no gpg recipient"
  if gpg --list-secret-keys --keyid-format long "$recipient" >/dev/null 2>&1; then
    skip "key $recipient already imported"
  else
    key=$(ask "Path to the secret key backup (gpg-secret-<KEYID>.asc): ")
    gpg --import "${key/#\~/$HOME}"
    trust=$(ask "Path to the ownertrust backup (Enter to skip): ")
    [ -z "$trust" ] || gpg --import-ownertrust "${trust/#\~/$HOME}"
    gpg --list-secret-keys --keyid-format long "$recipient" >/dev/null 2>&1 || fail "key $recipient still not available"
    ok "key $recipient imported"
  fi

  # -- 5. Seed the agent files before anything is decrypted ------------------
  step "GPG/SSH agent files"
  mkdir -p "$HOME/.gnupg" "$HOME/.ssh"
  chmod 700 "$HOME/.gnupg" "$HOME/.ssh"
  install -m 600 "$src/private_dot_gnupg/gpg-agent.conf" "$HOME/.gnupg/gpg-agent.conf"
  install -m 600 "$src/private_dot_gnupg/private_sshcontrol" "$HOME/.gnupg/sshcontrol"
  install -m 600 "$src/dot_ssh/config" "$HOME/.ssh/config"
  install -m 644 "$src/dot_ssh/id_personal.pub" "$HOME/.ssh/id_personal.pub"
  install -m 644 "$src/dot_ssh/id_work.pub" "$HOME/.ssh/id_work.pub"
  gpgconf --kill gpg-agent 2>/dev/null || true # fails when no agent runs yet
  gpgconf --launch gpg-agent
  ok "agent files copied, gpg-agent restarted"

  # -- 6. Decryption check ----------------------------------------------------
  step "Checking decryption (chezmoi diff)"
  chezmoi diff --no-pager --exclude=scripts >/dev/null ||
    fail "chezmoi diff failed: GnuPG cannot decrypt yet (key imported? agent running?). Fix it and run again."
  ok "encrypted files decrypt"
else
  exclude=(--exclude=encrypted)
fi

# -- 7. Apply ----------------------------------------------------------------
step "chezmoi apply"
chezmoi apply "${exclude[@]}" </dev/tty

step "Done"
echo "  Open a new shell. For SSH through GPG:"
# shellcheck disable=SC2016 # printed for the user to copy
echo '    export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"'
