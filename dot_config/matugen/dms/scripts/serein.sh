# Installs the Matugen-rendered theme into every Serein store found and selects it.
# Serein reads themes/<id>/package.json and themes/active.json at startup, so a
# running Serein shows the new colours after a restart.
set -euo pipefail
umask 077
# DMS runs hooks with a minimal PATH on NixOS.
PATH="/etc/profiles/per-user/$(id -un)/bin:/run/current-system/sw/bin:$PATH"

src="$HOME/.cache/matugen-dms/serein.json"
data="${XDG_DATA_HOME:-$HOME/.local/share}"

# Flatpak keeps its data under ~/.var/app; host builds use serein
# (packaged) or serein-development (source builds).
roots=()
if [[ "${SEREIN_DATA_DIR:-}" == /* ]]; then
  roots+=("$SEREIN_DATA_DIR")
else
  for d in "$HOME/.var/app/cz.viceverse.serein/data/serein" "$data/serein" "$data/serein-development"; do
    [[ -d "$d" ]] && roots+=("$d")
  done
fi
[[ ${#roots[@]} -gt 0 ]] || exit 0 # Serein never ran: nothing to theme.

id="$(jq -r .manifest.id "$src")"
compact="$(mktemp)"
trap 'rm -f "$compact"' EXIT
jq -c . "$src" >"$compact"

# Serein only checks the fingerprint's shape (64 hex digits, non-zero size).
stored="$(jq -n --slurpfile p "$compact" \
  --arg sha "$(sha256sum "$compact" | cut -d' ' -f1)" \
  --argjson size "$(wc -c <"$compact")" \
  '{local_theme: true, package: $p[0], grants: [], reviewed: false, sha256: $sha, download_bytes: $size}')"

for root in "${roots[@]}"; do
  dir="$root/extensions/themes"
  mkdir -p "$dir/$id"
  printf %s "$stored" >"$dir/$id/package.json.tmp"
  mv "$dir/$id/package.json.tmp" "$dir/$id/package.json"
  printf %s "$id" >"$dir/active.json.tmp"
  mv "$dir/active.json.tmp" "$dir/active.json"
done
