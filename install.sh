#!/usr/bin/env bash
# One-shot CLI bootstrap for Villoh/dotfiles on Linux. In any terminal:
#
#   curl -fsSL https://raw.githubusercontent.com/Villoh/dotfiles/main/install.sh | bash
#
# Follows docs/install/bootstrap.md: chezmoi init (its own prompts), the GPG
# key for the personal flow, the GPG/SSH agent files, a decryption check with
# chezmoi diff, and chezmoi apply. It installs no packages: on NixOS, Git,
# GnuPG, OpenSSH and chezmoi come from NixOS/Home Manager (see AGENTS.md).
# Answers are read from /dev/tty, so it works piped from curl.
set -euo pipefail

repo=Villoh/dotfiles

step() { printf '\n\033[36m== %s\033[0m\n' "$1"; }
ok() { printf '  \033[32m[OK]\033[0m   %s\n' "$1"; }
skip() { printf '  \033[33m[SKIP]\033[0m %s\n' "$1"; }
fail() { printf '  \033[31m[FAIL]\033[0m %s\n' "$1" >&2; exit 1; }
ask() { local answer; read -r -p "  $1" answer </dev/tty; printf '%s' "$answer"; }

[ "$(id -u)" -ne 0 ] || fail "run it as your user, not root: it sets up your home directory"
[ -r /dev/tty ] || fail "no terminal to answer the prompts (/dev/tty)"

# -- 1. Bootstrap tools ------------------------------------------------------
step "Bootstrap tools"
missing=""
for exe in git gpg chezmoi; do
  if command -v "$exe" >/dev/null 2>&1; then ok "$exe: $(command -v "$exe")"; else missing="$missing $exe"; fi
done
[ -z "$missing" ] || fail "missing:$missing. Install them with NixOS/Home Manager (or your package manager) and run this again."

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
