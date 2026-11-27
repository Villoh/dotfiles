#!/usr/bin/env bash
# Regenerates the installer's icon from packaging/icon.svg:
#   icon.png                  the window and taskbar icon (embedded in the app)
#   rsrc_windows_amd64.syso   the icon of dotfiles-installer.exe in Explorer,
#                             linked by `go build` for Windows only
# Needs ImageMagick (magick) and Go. Run it from installer/ after editing the SVG.
set -euo pipefail
cd "$(dirname "$0")/.."

magick -background none packaging/icon.svg -resize 256x256 icon.png
# --manifest none keeps the .exe as it was: go-winres' default manifest would
# change how Windows scales and elevates it.
go run github.com/tc-hib/go-winres@v0.3.3 simply \
  --arch amd64 --manifest none --icon icon.png \
  --product-name "Villoh/dotfiles installer" \
  --file-description "Villoh/dotfiles installer" \
  --original-filename dotfiles-installer.exe
