# ============================================================
# Bitwarden CLI – zsh Functions
# ============================================================

#region ── Session Management ──────────────────────────────

# Internal helper: returns current vault status
# Outputs: unauthenticated | locked | unlocked
_bw_status() {
  bw status | jq -r '.status'
}

# Unlock the vault and set the session key
# If not logged in, runs bw login first automatically
bwu() {
  local status=$(_bw_status)
  if [ "$status" = "unauthenticated" ]; then
    echo "Not logged in — running bw login first..."
    export BW_SESSION=$(bw login --raw)
  else
    export BW_SESSION=$(bw unlock --raw)
  fi
}

# Sync with the server and unlock in a single step
# If not logged in, runs bw login first automatically
bwstart() {
  local status=$(_bw_status)
  if [ "$status" = "unauthenticated" ]; then
    echo "Not logged in — running bw login first..."
    export BW_SESSION=$(bw login --raw)
  else
    export BW_SESSION=$(bw unlock --raw)
  fi
  bw sync
}

# Log in to Bitwarden with the chosen authentication method
# Saves the session key automatically after login
# Usage:
#   bwlogin            → login with email and password
#   bwlogin --sso      → login via SSO
#   bwlogin --apikey   → login via API Key
bwlogin() {
  case "$1" in
    --sso)    export BW_SESSION=$(bw login --sso --raw) ;;
    --apikey) export BW_SESSION=$(bw login --apikey --raw) ;;
    *)        export BW_SESSION=$(bw login --raw) ;;
  esac
  [ -n "$BW_SESSION" ] && echo "✓ Sesión iniciada correctamente"
}

# Manage the Bitwarden server configuration
# Usage:
#   bwconfig                              → show current server
#   bwconfig "https://my-server.com"      → set server
#   bwconfig "https://vault.bitwarden.eu" → EU server
#   bwconfig --reset                      → restore official server
bwconfig() {
  case "$1" in
    --reset)
      bw config server https://vault.bitwarden.com
      echo "✓ Server restored to vault.bitwarden.com"
      echo "! Remember to run bwlogin again"
      ;;
    "")
      echo "Current server: $(bw config server)"
      ;;
    *)
      bw config server "$1"
      echo "✓ Server set to: $1"
      echo "! Remember to run bwlogin again"
      ;;
  esac
}

# Lock the vault and clear the session variable
bwlock() {
  bw lock && unset BW_SESSION
}

#endregion

#region ── List & Search ───────────────────────────────────

# List vault items with fzf support for bulk actions
# Usage:
#   bwls                              → list all items
#   bwls --list-trash                 → list trashed items
#   bwls --folder "id"                → list items in a folder
#   bwls --trash                      → select with fzf and move to trash
#   bwls --delete                     → select with fzf and delete permanently
#   bwls --folder "id" --trash        → select items in folder with fzf and move to trash
#   bwls --folder "id" --delete       → select items in folder with fzf and delete permanently
unalias bwls 2>/dev/null
bwls() {
  local folderid="" action="" list_trash=0

  while [ $# -gt 0 ]; do
    case "$1" in
      --folder)     folderid="$2"; shift 2 ;;
      --trash)      action="trash";  shift ;;
      --delete)     action="delete"; shift ;;
      --list-trash) list_trash=1;    shift ;;
      *) echo "✗ Unknown argument: $1"; return 1 ;;
    esac
  done

  if [ "$list_trash" -eq 1 ]; then
    bw list items --trash | jq -r '.[] | "\(.id) — \(.name) — \(.login.username)"'
    return
  fi

  local items
  if [ -n "$folderid" ]; then
    items=$(bw list items --folderid "$folderid" | jq -r '.[] | "\(.id) \(.name) — \(.login.username)"')
  else
    items=$(bw list items | jq -r '.[] | "\(.id) \(.name) — \(.login.username)"')
  fi

  case "$action" in
    trash)
      local ids=$(echo "$items" | fzf --multi | awk '{print $1}')
      [ -z "$ids" ] && return 1
      echo "$ids" | xargs -I {} bw delete item {}
      echo "✓ Items moved to trash"
      ;;
    delete)
      local ids=$(echo "$items" | fzf --multi | awk '{print $1}')
      [ -z "$ids" ] && return 1
      echo "$ids" | xargs -I {} bw delete item {} --permanent
      echo "✓ Items permanently deleted"
      ;;
    *)
      echo "$items" | sed 's/^[^ ]* //' | sort
      ;;
  esac
}

# Search items by name, user or URL with support for actions
# Filters can be combined with each other
# Usage:
#   bwfind --name "github"
#   bwfind --user "you@email.com"
#   bwfind --url "github.com"
#   bwfind --name "github" --user "you@email.com"             → combined filters
#   bwfind --name "github" --show                             → show all fields
#   bwfind --name "github" --show password                    → show specific field
#   bwfind --name "github" --show attachment                  → list item attachments
#   bwfind --name "github" --copy                             → copy password to clipboard
#   bwfind --name "github" --copy username                    → copy specific field
#   bwfind --name "github" --copy attachment "name" "path"    → download attachment
#   bwfind --name "github" --exposed                          → check for security breaches
#   bwfind --name "github" --trash                            → move to trash with fzf
#   bwfind --name "github" --delete                           → delete with fzf
bwfind() {
  local name="" user="" url="" action="" field="" attachment_name="" attachment_output=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --name)  name="$2";  shift 2 ;;
      --user)  user="$2";  shift 2 ;;
      --url)   url="$2";   shift 2 ;;
      --show)
        action="show"
        if [ -n "$2" ] && [[ "$2" != --* ]]; then
          field="$2"; shift
        fi
        shift
        ;;
      --copy)
        action="copy"
        if [ -n "$2" ] && [[ "$2" != --* ]]; then
          field="$2"
          if [ "$field" = "attachment" ]; then
            [ -n "$3" ] && [[ "$3" != --* ]] && attachment_name="$3" && shift
            [ -n "$4" ] && [[ "$4" != --* ]] && attachment_output="$4" && shift
          fi
          shift
        else
          field="password"
        fi
        shift
        ;;
      --exposed) action="exposed"; shift ;;
      --trash)   action="trash";   shift ;;
      --delete)  action="delete";  shift ;;
      *) echo "✗ Unknown argument: $1"; return 1 ;;
    esac
  done

  if [ -z "$name" ] && [ -z "$user" ] && [ -z "$url" ]; then
    echo "✗ You must specify at least one filter: --name, --user or --url"
    return 1
  fi

  # Build jq filter combining the provided criteria using --arg to avoid injection
  local filter='.[]'
  local jq_args=()
  [ -n "$name" ] && filter+=' | select(.name | ascii_downcase | contains($name))' && jq_args+=(--arg name "${name:l}")
  [ -n "$user" ] && filter+=' | select(.login.username == $user)'                 && jq_args+=(--arg user "$user")
  [ -n "$url"  ] && filter+=' | select(.login.uris != null and (.login.uris[] | .uri | contains($url)))' && jq_args+=(--arg url "$url")

  local results=$(bw list items | jq "${jq_args[@]}" -r "[${filter}] | .[] | \"\(.id) \(.name) — \(.login.username)\"")

  if [ -z "$results" ]; then
    echo "✗ No items found"
    return 1
  fi

  # Select item — if only one result select directly, otherwise use fzf
  _select_item() {
    if [ "$(echo "$results" | wc -l)" -eq 1 ]; then
      echo "$results" | awk '{print $1}'
    else
      echo "$results" | fzf | awk '{print $1}'
    fi
  }

  case "$action" in
    show)
      local id=$(_select_item)
      [ -z "$id" ] && return 1
      if [ -z "$field" ]; then
        bw get item "$id" | jq '{
          id: .id,
          name: .name,
          username: .login.username,
          password: .login.password,
          uris: [.login.uris[]?.uri],
          totp: .login.totp,
          notes: .notes
        }'
      elif [ "$field" = "attachment" ]; then
        bw get item "$id" | jq -r '.attachments[]? | "\(.id) — \(.fileName) — \(.sizeName)"'
      else
        bw get "$field" "$id"
      fi
      ;;
    copy)
      local id=$(_select_item)
      [ -z "$id" ] && return 1
      if [ "$field" = "attachment" ]; then
        [ -z "$attachment_name" ] && echo "✗ You must specify the attachment name with --copy attachment 'name'" && return 1
        local bw_args=(get attachment "$attachment_name" --itemid "$id")
        [ -n "$attachment_output" ] && bw_args+=(--output "$attachment_output")
        bw "${bw_args[@]}" && echo "✓ Attachment downloaded"
      else
        bw get "$field" "$id" | wl-copy
        echo "✓ $field copied to clipboard"
      fi
      ;;
    exposed)
      local id=$(_select_item)
      [ -z "$id" ] && return 1
      local count=$(bw get exposed "$id")
      if [ "$count" -gt 0 ]; then
        echo "⚠ Password found in $count security breaches"
      else
        echo "✓ Password not found in any security breach"
      fi
      ;;
    trash)
      local ids=$(echo "$results" | fzf --multi | awk '{print $1}')
      [ -z "$ids" ] && return 1
      echo "$ids" | xargs -I {} bw delete item {}
      echo "✓ Items moved to trash"
      ;;
    delete)
      local ids=$(echo "$results" | fzf --multi | awk '{print $1}')
      [ -z "$ids" ] && return 1
      echo "$ids" | xargs -I {} bw delete item {} --permanent
      echo "✓ Items permanently deleted"
      ;;
    *)
      echo "$results" | sort
      ;;
  esac
}

# Show the full details of an item by ID in readable JSON
# Usage: bwitem "id"
bwitem() {
  if [ -z "$1" ]; then
    echo "✗ You must specify an ID"
    return 1
  fi
  bw get item "$1" | jq '.'
}

#endregion

#region ── Edit & Move ─────────────────────────────────────

# Edit an item, folder, collection or item-collections interactively
# Shows current values as defaults — leave empty to keep the current value
# Usage:
#   bwedit item "id"             → edit a login item fields interactively
#   bwedit folder "id"           → rename a folder
#   bwedit org-collection "id"   → rename a collection
#   bwedit item-collections "id" → edit collections an item belongs to
bwedit() {
  local type="$1" id="$2"

  if [ -z "$type" ] || [ -z "$id" ]; then
    echo "✗ Usage: bwedit (item|folder|org-collection|item-collections) \"id\""
    return 1
  fi

  case "$type" in
    item)
      local current=$(bw get item "$id")
      local cur_name=$(echo $current     | jq -r '.name')
      local cur_username=$(echo $current | jq -r '.login.username // ""')
      local cur_password=$(echo $current | jq -r '.login.password // ""')
      local cur_uri=$(echo $current      | jq -r '.login.uris[0].uri // ""')
      local cur_notes=$(echo $current    | jq -r '.notes // ""')

      read "name?Name [$cur_name]: "
      read "username?Username [$cur_username]: "
      read "password?Password (leave empty to keep, \"gen\" to generate): "
      read "uri?URL [$cur_uri]: "
      read "notes?Notes (leave empty to keep): "

      if [ -z "$password" ]; then
        password="$cur_password"
      elif [ "$password" = "gen" ]; then
        password=$(_bwgen_interactive)
        echo "✓ Password generated: $password"
      fi

      name=${name:-$cur_name}
      username=${username:-$cur_username}
      uri=${uri:-$cur_uri}
      notes=${notes:-$cur_notes}

      # Use --arg to safely handle special characters in values
      echo $current | jq \
        --arg name     "$name"     \
        --arg username "$username" \
        --arg password "$password" \
        --arg uri      "$uri"      \
        --arg notes    "$notes"    \
        '.name=$name | .login.username=$username | .login.password=$password | .login.uris[0].uri=$uri | .notes=$notes' \
        | bw encode | bw edit item "$id" > /dev/null && echo "✓ Item updated successfully"
      ;;

    folder)
      local cur_name=$(bw get folder "$id" | jq -r '.name')
      read "fname?Folder name [$cur_name]: "
      fname=${fname:-$cur_name}

      bw get folder "$id" | jq --arg name "$fname" '.name = $name' | bw encode | bw edit folder "$id" > /dev/null && echo "✓ Folder renamed successfully"
      ;;

    org-collection)
      echo "Available organizations:"
      bw list organizations | jq -r '.[] | "\(.id) — \(.name)"'
      read "orgid?Organization ID: "
      if [ -z "$orgid" ]; then
        echo "✗ Organization ID is required"
        return 1
      fi

      local current=$(bw get org-collection "$id" --organizationid "$orgid")
      local cur_name=$(echo $current | jq -r '.name')
      read "cname?Collection name [$cur_name]: "
      cname=${cname:-$cur_name}

      echo $current | jq --arg name "$cname" '.name = $name' | bw encode | bw edit org-collection "$id" --organizationid "$orgid" > /dev/null && echo "✓ Collection renamed successfully"
      ;;

    item-collections)
      echo "Available collections:"
      bw list org-collections | jq -r '.[] | "\(.id) — \(.name)"'
      echo "Enter collection IDs separated by spaces:"
      read "collectionids?"

      local ids_json=$(echo $collectionids | tr ' ' '\n' | jq -R . | jq -s .)
      echo $ids_json | bw encode | bw edit item-collections "$id" > /dev/null && echo "✓ Item collections updated successfully"
      ;;

    *)
      echo "✗ Unknown type: $type. Valid types: item, folder, org-collection, item-collections"
      return 1
      ;;
  esac
}

# Move an item to a different folder interactively
# Usage:
#   bwmv "item-id"              → select destination folder with fzf
#   bwmv "item-id" "folder-id"  → move directly to specified folder
bwmv() {
  local itemid="$1" folderid="$2"

  if [ -z "$itemid" ]; then
    echo "✗ You must specify an item ID"
    return 1
  fi

  if [ -z "$folderid" ]; then
    folderid=$(bw list folders | jq -r '.[] | select(.name != "No Folder") | "\(.id) \(.name)"' | fzf | awk '{print $1}')
    [ -z "$folderid" ] && return 1
  fi

  bw get item "$itemid" | jq --arg fid "$folderid" '.folderId = $fid' | bw encode | bw edit item "$itemid" > /dev/null && echo "✓ Item moved successfully"
}

#endregion

#region ── Attachments ─────────────────────────────────────

# Manage vault attachments
# Usage:
#   bwattachment --all / -a                                       → list all attachments across all items
#   bwattachment --itemid "id"                                    → list attachments of an item
#   bwattachment --add --file "path" --itemid "id"                → add attachment to an item
#   bwattachment --name "photo.jpg" --itemid "id"                 → download to current directory
#   bwattachment --name "photo.jpg" --itemid "id" --output "path" → download to specific path
bwattachment() {
  local itemid="" name="" output="" file="" action=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --all|-a)
        bw list items | jq -r '.[] | select(.attachments != null) | .name as $item | .attachments[] | "\($item) — \(.id) — \(.fileName) — \(.sizeName)"'
        return
        ;;
      --itemid) itemid="$2"; shift 2 ;;
      --name)   name="$2";   shift 2 ;;
      --output) output="$2"; shift 2 ;;
      --file)   file="$2";   shift 2 ;;
      --add)    action="add"; shift ;;
      *) echo "✗ Unknown argument: $1"; return 1 ;;
    esac
  done

  if [ -z "$itemid" ]; then
    echo "✗ You must specify --itemid"
    return 1
  fi

  case "$action" in
    add)
      if [ -z "$file" ]; then
        echo "✗ You must specify --file"
        return 1
      fi
      bw create attachment --file "$file" --itemid "$itemid" && echo "✓ Attachment added"
      ;;
    *)
      if [ -z "$name" ]; then
        bw get item "$itemid" | jq -r '.attachments[]? | "\(.id) — \(.fileName) — \(.sizeName)"'
      else
        local bw_args=(get attachment "$name" --itemid "$itemid")
        [ -n "$output" ] && bw_args+=(--output "$output")
        bw "${bw_args[@]}" && echo "✓ Attachment downloaded"
      fi
      ;;
  esac
}

#endregion

#region ── Folders & Collections ──────────────────────────

# Internal helper: creates a folder interactively
# Do not call directly, use bwfolder --add or bwadd
_bwfolder_create() {
  local fname=""
  while [ -z "$fname" ]; do
    read "fname?Folder name (required): "
  done
  bw get template folder | jq --arg name "$fname" '.name = $name' | bw encode | bw create folder > /dev/null && echo "✓ Folder created"
}

# Manage vault folders
# Usage:
#   bwfolder --all / -a       → list all folders
#   bwfolder "id"             → show folder details
#   bwfolder --add            → create a folder interactively
#   bwfolder --delete         → select with fzf and delete
#   bwfolder "id" --delete    → delete specific folder directly
bwfolder() {
  local folderid="" action=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --all|-a)  action="list";   shift ;;
      --add)     action="add";    shift ;;
      --delete)  action="delete"; shift ;;
      *)         folderid="$1";   shift ;;
    esac
  done

  case "$action" in
    list)
      bw list folders | jq -r '.[] | select(.name != "No Folder") | "\(.id) — \(.name)"'
      ;;
    add)
      _bwfolder_create
      ;;
    delete)
      if [ -z "$folderid" ]; then
        folderid=$(bw list folders | jq -r '.[] | select(.name != "No Folder") | "\(.id) \(.name)"' | fzf | awk '{print $1}')
        [ -z "$folderid" ] && return 1
      fi
      bw delete folder "$folderid" && echo "✓ Folder deleted"
      ;;
    *)
      if [ -z "$folderid" ]; then
        echo "✗ You must specify an ID, --all / -a, --add, or --delete"
        return 1
      fi
      bw get folder "$folderid" | jq '.'
      ;;
  esac
}

# Internal helper: creates a collection interactively
# Do not call directly, use bwcollection --add
_bwcollection_create() {
  echo "Available organizations:" >&2
  bw list organizations | jq -r '.[] | "\(.id) — \(.name)"' >&2
  read "orgid?Organization ID: "
  if [ -z "$orgid" ]; then
    echo "✗ Organization ID is required"
    return 1
  fi

  local cname=""
  while [ -z "$cname" ]; do
    read "cname?Collection name (required): "
  done

  read "externalid?External ID (leave empty for none): "

  bw get template collection | jq \
    --arg org  "$orgid"      \
    --arg name "$cname"      \
    --arg ext  "$externalid" \
    '.organizationId=$org | .name=$name | .externalId=(if $ext == "" then null else $ext end)' \
    | bw encode | bw create org-collection --organizationid "$orgid" > /dev/null && echo "✓ Collection created"
}

# Manage organization collections
# Usage:
#   bwcollection --all / -a   → list all collections
#   bwcollection "id"         → show collection details
#   bwcollection --add        → create a collection interactively
bwcollection() {
  case "$1" in
    --all|-a) bw list org-collections | jq -r '.[] | "\(.id) — \(.name)"' ;;
    --add)    _bwcollection_create ;;
    *)
      if [ -z "$1" ]; then
        echo "✗ You must specify an ID, --all / -a, or --add"
        return 1
      fi
      bw get org-collection "$1" | jq '.'
      ;;
  esac
}

#endregion

#region ── Templates ───────────────────────────────────────

# Show available vault templates
# Usage:
#   bwtemplate --all / -a   → list all available templates
#   bwtemplate "name"       → show a specific template
bwtemplate() {
  local valid_templates=(item item.field item.login item.login.uri item.card item.identity item.securenote folder collection item-collections org-collection)

  case "$1" in
    --all|-a)
      echo "Available templates:"
      for t in "${valid_templates[@]}"; do
        echo "  • $t"
      done
      ;;
    *)
      if [ -z "$1" ]; then
        echo "✗ You must specify a template or --all / -a"
        return 1
      fi
      bw get template "$1" | jq '.'
      ;;
  esac
}

#endregion

#region ── Add Items ───────────────────────────────────────

# Internal helper: prompts for a folder interactively and returns its ID
# Do not call directly
_bwadd_select_folder() {
  local folders=$(bw list folders | jq '[.[] | select(.name != "No Folder")]')
  local count=$(echo $folders | jq 'length')

  if [ "$count" -gt 0 ]; then
    echo "\nAvailable folders:" >&2
    echo $folders | jq -r 'to_entries[] | "\(.key + 1)) \(.value.name)"' >&2
    read "foldernum?Folder number (leave empty for none): "
    if [ -n "$foldernum" ]; then
      echo $folders | jq -r ".[$foldernum - 1].id"
    fi
  fi
}

# Internal helper: creates a Login item (type=1)
# Removes the totp field from the template to avoid creating an empty TOTP field
_bwadd_login() {
  read "uri?URL: "
  read "username?Username: "
  read "password?Password (leave empty to generate one): "

  if [ -z "$password" ]; then
    password=$(_bwgen_interactive)
    echo "✓ Password generated" >&2
  fi

  bw get template item.login | jq \
    --arg user "$username" \
    --arg pass "$password" \
    --arg uri  "$uri"      \
    'del(.totp) | .username=$user | .password=$pass | .uris=[{"match":null,"uri":$uri}]'
}

# Internal helper: creates a Card item (type=3)
_bwadd_card() {
  read "cardholder?Cardholder name: "
  read "brand?Brand (visa/mastercard/amex/discover/diners/jcb/maestro/unionpay): "
  read "number?Card number: "
  read "expmonth?Expiration month (01-12): "
  read "expyear?Expiration year: "
  read "code?CVV: "

  bw get template item.card | jq \
    --arg ch  "$cardholder" \
    --arg br  "$brand"      \
    --arg num "$number"     \
    --arg em  "$expmonth"   \
    --arg ey  "$expyear"    \
    --arg cvv "$code"       \
    '.cardholderName=$ch | .brand=$br | .number=$num | .expMonth=$em | .expYear=$ey | .code=$cvv'
}

# Internal helper: creates an Identity item (type=4)
_bwadd_identity() {
  read "title?Title (Mr/Mrs/Ms/Dr): "
  read "firstname?First name: "
  read "middlename?Middle name: "
  read "lastname?Last name: "
  read "company?Company: "
  read "email?Email: "
  read "phone?Phone: "
  read "address1?Address: "
  read "address2?Address (line 2): "
  read "city?City: "
  read "state?State/Province: "
  read "postalcode?Postal code: "
  read "country?Country: "
  read "username?Username: "
  read "ssn?SSN: "
  read "passport?Passport number: "
  read "license?Driver's license number: "

  bw get template item.identity | jq \
    --arg title  "$title"      \
    --arg fn     "$firstname"  \
    --arg mn     "$middlename" \
    --arg ln     "$lastname"   \
    --arg co     "$company"    \
    --arg em     "$email"      \
    --arg ph     "$phone"      \
    --arg a1     "$address1"   \
    --arg a2     "$address2"   \
    --arg ci     "$city"       \
    --arg st     "$state"      \
    --arg pc     "$postalcode" \
    --arg cn     "$country"    \
    --arg un     "$username"   \
    --arg ssn    "$ssn"        \
    --arg pp     "$passport"   \
    --arg lic    "$license"    \
    '.title=$title | .firstName=$fn | .middleName=$mn | .lastName=$ln |
     .company=$co | .email=$em | .phone=$ph |
     .address1=$a1 | .address2=$a2 | .city=$ci | .state=$st |
     .postalCode=$pc | .country=$cn | .username=$un |
     .ssn=$ssn | .passportNumber=$pp | .licenseNumber=$lic'
}

# Internal helper: creates an SSH Key item (type=5)
# No official template available, built manually
_bwadd_sshkey() {
  read "privatekey?Private key: "
  read "publickey?Public key: "
  read "fingerprint?Fingerprint: "

  jq -n \
    --arg priv "$privatekey"  \
    --arg pub  "$publickey"   \
    --arg fp   "$fingerprint" \
    '{"privateKey":$priv,"publicKey":$pub,"fingerprint":$fp}'
}

# Add a new item or folder interactively
# Supports all item types: login, securenote, card, identity, sshkey, folder
# Usage: bwadd
bwadd() {
  echo "Available types:"
  echo "  1) Login"
  echo "  2) Secure Note"
  echo "  3) Card"
  echo "  4) Identity"
  echo "  5) SSH Key"
  echo "  6) Folder"
  read "type?Type [1]: "
  type=${type:-1}

  if [ "$type" = "6" ]; then
    _bwfolder_create
    return
  fi

  local name=""
  while [ -z "$name" ]; do
    read "name?Item name (required): "
  done

  read "notes?Notes: "

  local subobject subfield
  case "$type" in
    1) subfield="login";      subobject=$(_bwadd_login)     ;;
    2) subfield="secureNote"; subobject=$(bw get template item.securenote) ;;
    3) subfield="card";       subobject=$(_bwadd_card)      ;;
    4) subfield="identity";   subobject=$(_bwadd_identity)  ;;
    5) subfield="sshKey";     subobject=$(_bwadd_sshkey)    ;;
    *) echo "✗ Invalid type"; return 1 ;;
  esac

  local folderid=$(_bwadd_select_folder)

  local item=$(bw get template item | jq \
    --argjson type "$type"       \
    --arg     name "$name"       \
    --arg     notes "$notes"     \
    --argjson sub  "$subobject"  \
    ".type=\$type | .name=\$name | .notes=\$notes | .$subfield=\$sub")

  if [ -n "$folderid" ]; then
    item=$(echo $item | jq --arg fid "$folderid" '.folderId = $fid')
  fi

  echo $item | bw encode | bw create item > /dev/null && echo "✓ Item created successfully"
}

#endregion

#region ── Generate ────────────────────────────────────────

# Internal helper: generates a password/passphrase interactively and returns it via stdout
# Do not call directly, use bwgen or bwadd
_bwgen_interactive() {
  local -a args

  read "type?Type (password/passphrase) [password]: "
  type=${type:-password}

  if [ "$type" = "passphrase" ]; then
    read "words?Number of words [3]: "
    args+=(-p --words ${words:-3})

    read "separator?Separator [_]: "
    args+=(--separator ${separator:-_})

    read "capitalize?Capitalize? (y/n) [n]: "
    [ "$capitalize" = "y" ] && args+=(-c)

    read "includenumber?Include number? (y/n) [n]: "
    [ "$includenumber" = "y" ] && args+=(--includeNumber)
  else
    read "length?Length [25]: "
    args+=(--length ${length:-25})

    read "uppercase?Uppercase? (y/n) [y]: "
    [ "${uppercase:-y}" = "y" ] && args+=(-u)

    read "lowercase?Lowercase? (y/n) [y]: "
    [ "${lowercase:-y}" = "y" ] && args+=(-l)

    read "numbers?Numbers? (y/n) [y]: "
    [ "${numbers:-y}" = "y" ] && args+=(-n)

    read "special?Special characters? (y/n) [y]: "
    [ "${special:-y}" = "y" ] && args+=(-s)

    read "ambiguous?Avoid ambiguous characters? (y/n) [n]: "
    [ "$ambiguous" = "y" ] && args+=(--ambiguous)

    read "minnumber?Minimum numbers [0]: "
    [ -n "$minnumber" ] && [ "$minnumber" -gt 0 ] && args+=(--minNumber "$minnumber")

    read "minspecial?Minimum special characters [0]: "
    [ -n "$minspecial" ] && [ "$minspecial" -gt 0 ] && args+=(--minSpecial "$minspecial")
  fi

  bw generate "${args[@]}"
}

# Generate a password/passphrase interactively and copy it to the clipboard
# Usage: bwgen
bwgen() {
  local generated=$(_bwgen_interactive)
  echo "$generated" | wl-copy
  echo "✓ Password generated and copied: $generated"
}

#endregion

#region ── Delete & Restore ────────────────────────────────

# Move an item to the trash by ID (auto-deleted after 30 days)
# Usage: bwtrash "id"
bwtrash() {
  bw delete item "$1" && echo "✓ Item moved to trash"
}

# Permanently delete an item or folder by ID
# Usage: bwdelete "id" / bwdelete item "id" / bwdelete folder "id"
bwdelete() {
  if [ "$1" = "folder" ]; then
    bw delete folder "$2" && echo "✓ Folder deleted"
  elif [ "$1" = "item" ]; then
    bw delete item "$2" --permanent && echo "✓ Item permanently deleted"
  else
    bw delete item "$1" --permanent && echo "✓ Item permanently deleted"
  fi
}

# Empty the trash by permanently deleting all items in it
bwempty() {
  bw list items --trash | jq -r '.[].id' | xargs -I {} bw delete item {} --permanent
  echo "✓ Trash emptied"
}

# Restore an item from the trash before it is auto-deleted
# Usage: bwrestore "id"
bwrestore() {
  bw restore item "$1" && echo "✓ Item restored"
}

#endregion
