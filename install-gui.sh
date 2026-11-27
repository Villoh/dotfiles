#!/usr/bin/env bash
# GUI installer for Villoh/dotfiles on Linux (the CLI flow is install.sh):
#
#   curl -fsSL https://raw.githubusercontent.com/Villoh/dotfiles/main/install-gui.sh | bash
#
# NixOS builds the installer from the flake; other distributions download the
# AppImage of the latest installer-v* release and check its SHA-256 against
# the release's SHA256SUMS. Either way it starts without waiting, so the
# terminal is free once the window opens.
set -euo pipefail

repo=Villoh/dotfiles
name=dotfiles-installer-x86_64.AppImage
base=https://github.com/$repo/releases/latest/download

fail() { printf '\033[31m%s\033[0m\n' "$1" >&2; exit 1; }
start() { # detach from this terminal, keeping a log of what it prints
  setsid "$@" >"${TMPDIR:-/tmp}/dotfiles-installer-launch.log" 2>&1 </dev/null &
  printf '\033[32mThe installer runs in its own window; this terminal is free.\033[0m\n'
}

[ "$(id -u)" -ne 0 ] || fail "run it as your user, not root: it sets up your home directory"

# NixOS has no libraries at the paths an AppImage expects: build the flake.
if [ -e /etc/NIXOS ]; then
  command -v nix >/dev/null 2>&1 || fail "nix not found"
  printf '\033[36mBuilding the installer from the flake...\033[0m\n'
  out=$(nix --extra-experimental-features 'nix-command flakes' build "github:$repo" --no-link --print-out-paths)
  start "$out/bin/dotfiles-installer"
  exit 0
fi

[ "$(uname -m)" = x86_64 ] || fail "the AppImage is x86_64 only; with Nix, run: nix run github:$repo"

dir=${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles-installer
mkdir -p "$dir"
printf '\033[36mDownloading %s...\033[0m\n' "$name"
curl -fsSL -o "$dir/$name" "$base/$name"
curl -fsSL -o "$dir/SHA256SUMS" "$base/SHA256SUMS"
(cd "$dir" && grep -E "^[0-9a-f]{64}  \*?$name\$" SHA256SUMS | sha256sum -c --quiet -) ||
  { rm -f "$dir/$name"; fail "SHA-256 mismatch for $name"; }
chmod +x "$dir/$name"
printf '\033[32mChecksum OK. Starting the installer...\033[0m\n'

# The AppImage runtime mounts itself with FUSE; without fusermount, extract.
if ! command -v fusermount >/dev/null 2>&1 && ! command -v fusermount3 >/dev/null 2>&1; then
  export APPIMAGE_EXTRACT_AND_RUN=1
fi
start "$dir/$name"
