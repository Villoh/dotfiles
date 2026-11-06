# Installs the Matugen-rendered theme into Serein's store and selects it.
# Serein reads themes/<id>/package.json and themes/active.json at startup, so a
# running Serein shows the new colours after a restart.
set -euo pipefail
umask 077
# DMS runs hooks with a minimal PATH on NixOS.
PATH="/etc/profiles/per-user/$(id -un)/bin:/run/current-system/sw/bin:$PATH"

src="$HOME/.cache/matugen-dms/serein.json"
data="${XDG_DATA_HOME:-$HOME/.local/share}"
root=""
if [[ "${SEREIN_DATA_DIR:-}" == /* ]]; then
  root="$SEREIN_DATA_DIR"
else
  # Source builds (this flake's package) use serein-development.
  for d in serein-development serein; do
    [[ -d "$data/$d" ]] && root="$data/$d" && break
  done
fi
[[ -n "$root" ]] || exit 0 # Serein never ran: nothing to theme.

id="$(jq -r .manifest.id "$src")"
dir="$root/extensions/themes"
mkdir -p "$dir/$id"

compact="$(mktemp)"
trap 'rm -f "$compact"' EXIT
jq -c . "$src" >"$compact"

# Serein only checks the fingerprint's shape (64 hex digits, non-zero size).
jq -n --slurpfile p "$compact" \
  --arg sha "$(sha256sum "$compact" | cut -d' ' -f1)" \
  --argjson size "$(wc -c <"$compact")" \
  '{local_theme: true, package: $p[0], grants: [], reviewed: false, sha256: $sha, download_bytes: $size}' \
  >"$dir/$id/package.json.tmp"
mv "$dir/$id/package.json.tmp" "$dir/$id/package.json"

printf %s "$id" >"$dir/active.json.tmp"
mv "$dir/active.json.tmp" "$dir/active.json"
