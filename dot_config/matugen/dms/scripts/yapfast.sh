# Merges the Matugen-rendered theme into Yapfast's layout.json as the custom
# theme "DMS" and selects it. Yapfast reads layout.json at startup and rewrites
# it from memory, so close Yapfast first or it overwrites this on its next save.
set -euo pipefail
umask 077
# DMS runs hooks with a minimal PATH on NixOS.
PATH="/etc/profiles/per-user/$(id -un)/bin:/run/current-system/sw/bin:$PATH"

src="$HOME/.cache/matugen-dms/yapfast.json"
layout="${XDG_DATA_HOME:-$HOME/.local/share}/yapfast/layout.json"
[[ -f "$layout" ]] || exit 0 # Yapfast never ran: nothing to theme.

# Keep the id of an existing "DMS" theme; otherwise take the next free custom:N.
tmp="$(mktemp "$layout.XXXXXX")"
trap 'rm -f "$tmp"' EXIT
jq --slurpfile t "$src" '
  (.custom_themes // []) as $c
  | (($c | map(select(.name == "DMS")) | first | .id)
     // ("custom:" + (([$c[].id | capture("^custom:(?<n>[0-9]+)$").n | tonumber] | (max // 0) + 1) | tostring))) as $id
  | .custom_themes = ($c | map(select(.name != "DMS"))) + [$t[0] + {id: $id}]
  | .theme = $id' "$layout" >"$tmp"
mv "$tmp" "$layout"
trap - EXIT
