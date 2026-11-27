#!/usr/bin/env bash
# Packs the Linux installer binary into an AppImage:
#   installer/packaging/appimage.sh <binary> <out.AppImage>
# Downloads appimagetool and the type2 runtime at pinned versions and checks
# their SHA-256. The AppImage bundles no libraries: like the binary, it loads
# the host's GTK 3, Pango, epoxy, Wayland/X11 and GL. NixOS has none of them
# at fixed paths, so NixOS uses the flake (nix run github:Villoh/dotfiles).
set -euo pipefail

bin=${1:?usage: appimage.sh <binary> <out.AppImage>}
out=${2:?usage: appimage.sh <binary> <out.AppImage>}
here=$(cd "$(dirname "$0")" && pwd)

tool_url=https://github.com/AppImage/appimagetool/releases/download/1.9.1/appimagetool-x86_64.AppImage
tool_sha=ed4ce84f0d9caff66f50bcca6ff6f35aae54ce8135408b3fa33abfc3cb384eb0
runtime_url=https://github.com/AppImage/type2-runtime/releases/download/20251108/runtime-x86_64
runtime_sha=2fca8b443c92510f1483a883f60061ad09b46b978b2631c807cd873a47ec260d

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

fetch() { # url sha256 dest
  curl -fsSL -o "$3" "$1"
  echo "$2  $3" | sha256sum -c --quiet -
}
fetch "$tool_url" "$tool_sha" "$work/appimagetool"
fetch "$runtime_url" "$runtime_sha" "$work/runtime"
chmod +x "$work/appimagetool"

app="$work/AppDir"
install -Dm755 "$bin" "$app/usr/bin/dotfiles-installer"
install -Dm644 "$here/dotfiles-installer.desktop" "$app/dotfiles-installer.desktop"
install -Dm644 "$here/icon.svg" "$app/dotfiles-installer.svg"
ln -s dotfiles-installer.svg "$app/.DirIcon"
ln -s usr/bin/dotfiles-installer "$app/AppRun"

# The extracted tool runs without FUSE, as in CI containers.
ARCH=x86_64 APPIMAGE_EXTRACT_AND_RUN=1 "$work/appimagetool" --no-appstream \
  --runtime-file "$work/runtime" "$app" "$out"
