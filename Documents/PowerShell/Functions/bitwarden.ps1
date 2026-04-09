# ============================================================
# Bitwarden CLI - PowerShell Functions
# Converted from zsh. Sin dependencia de jq (PowerShell nativo).
#
# Coloca este fichero en:
#   $HOME\Documents\PowerShell\bw-functions.ps1
#
# Y añade esta linea a tu $PROFILE
#   ($HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1):
#   . "$PSScriptRoot\bw-functions.ps1"
#
# Requirements: bw CLI
# Opcional:      fzf (si no esta instalado se usa Out-GridView)
# ============================================================

# Forzar UTF-8 para que el output del CLI de bw se interprete correctamente
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8

#region ── Helpers JSON ────────────────────────────────────────────────────────

<#
.SYNOPSIS
    Serializa un objeto PowerShell a JSON y lo codifica en Base64 para bw.
    Equivale al patron: objeto | jq ... | bw encode
.NOTES
    En lugar de pasar el JSON por pipe a "bw encode" (lo que causa problemas
    de encoding en Windows con caracteres especiales como tildes), hacemos el
    Base64 directamente en PowerShell con UTF-8 garantizado.
    Tambien restauramos arrays vacios que ConvertTo-Json serializa como null.
#>
function _bw_encode {
    param([Parameter(ValueFromPipeline)]$Object)
    process {
        $json = $Object | ConvertTo-Json -Depth 10 -Compress

        # PowerShell colapsa arrays de un elemento a objeto al serializar.
        # bw espera siempre arrays para estos campos, los restauramos:

        # 1. Arrays vacios serializados como null → []
        $json = $json -replace '"(collectionIds|fields|passwordHistory)":null', '"$1":[]'
        $json = $json -replace '"uris":null', '"uris":[]'

        # 2. Array uris con un solo elemento serializado como objeto → [objeto]
        #    Patron: "uris":{...} donde el objeto uri no contiene llaves anidadas
        if ($json -match '"uris":\{') {
            $json = [regex]::Replace($json, '"uris":(\{[^}]*\})', '"uris":[$1]')
        }

        # Base64 en UTF-8 puro, sin depender del encoding del pipe de Windows
        $bytes   = [System.Text.Encoding]::UTF8.GetBytes($json)
        $encoded = [Convert]::ToBase64String($bytes)
        Write-Output $encoded
    }
}

<#
.SYNOPSIS
    Muestra un objeto como JSON indentado y legible. Equivale a jq '.'.
#>
function _bw_pretty {
    param([Parameter(ValueFromPipeline)]$Object)
    process {
        if ($Object -is [string]) {
            $Object | ConvertFrom-Json -Depth 10 | ConvertTo-Json -Depth 10
        } else {
            $Object | ConvertTo-Json -Depth 10
        }
    }
}

#endregion

#region ── fzf / Selector ─────────────────────────────────────────────────────

<#
.SYNOPSIS
    Helper interno. Selector interactivo de lineas.
    Usa fzf si esta disponible; si no, usa Out-GridView (nativo de Windows).
.PARAMETER Multi
    Permite seleccionar multiples elementos.
.OUTPUTS
    [string[]] Lineas seleccionadas.
#>
function _bw_select {
    param(
        [Parameter(ValueFromPipeline)][string[]]$InputLines,
        [switch]$Multi
    )
    begin   { $all = @() }
    process { $all += $InputLines }
    end {
        if (Get-Command fzf -ErrorAction SilentlyContinue) {
            if ($Multi) { $all | fzf --multi }
            else        { $all | fzf }
        } else {
            $title = if ($Multi) { 'Selecciona uno o varios items (Ctrl+Click para multi)' } else { 'Selecciona un item' }
            $selected = $all | Out-GridView -Title $title -PassThru
            $selected
        }
    }
}

#endregion

#region ── Session Management ──────────────────────────────────────────────────

<#
.SYNOPSIS
    Devuelve el estado actual del vault: unauthenticated, locked o unlocked.
.OUTPUTS
    [string] Estado del vault.
#>
function _bw_status {
    (bw status | ConvertFrom-Json).status
}

<#
.SYNOPSIS
    Desbloquea el vault y guarda la clave de sesion en la variable de entorno.
    Si no hay sesion iniciada, ejecuta bw login primero automaticamente.
#>
function bwu {
    $status = _bw_status
    if ($status -eq 'unauthenticated') {
        Write-Host 'Not logged in - running bw login first...'
        $env:BW_SESSION = bw login --raw
    } else {
        $env:BW_SESSION = bw unlock --raw
    }
}

<#
.SYNOPSIS
    Desbloquea el vault y sincroniza con el servidor en un solo paso.
    Si no hay sesion iniciada, ejecuta bw login primero automaticamente.
#>
function bwstart {
    $status = _bw_status
    if ($status -eq 'unauthenticated') {
        Write-Host 'Not logged in - running bw login first...'
        $env:BW_SESSION = bw login --raw
    } else {
        $env:BW_SESSION = bw unlock --raw
    }
    bw sync
}

<#
.SYNOPSIS
    Inicia sesion en Bitwarden con el metodo de autenticacion elegido.
    Tras el login guarda la clave de sesion automaticamente.
.PARAMETER Sso
    Autenticacion mediante SSO (Single Sign-On).
.PARAMETER ApiKey
    Autenticacion mediante API Key (CLIENT_ID / CLIENT_SECRET).
.EXAMPLE
    bwlogin              # login con email y contrasena
    bwlogin -Sso         # login via SSO
    bwlogin -ApiKey      # login via API Key
#>
function bwlogin {
    param(
        [switch]$Sso,
        [switch]$ApiKey
    )

    if ($Sso) {
        $env:BW_SESSION = bw login --sso --raw
    } elseif ($ApiKey) {
        $env:BW_SESSION = bw login --apikey --raw
    } else {
        $env:BW_SESSION = bw login --raw
    }

    if ($env:BW_SESSION) {
        Write-Host 'OK Sesion iniciada correctamente'
    }
}

<#
.SYNOPSIS
    Gestiona la configuracion del servidor de Bitwarden.
.PARAMETER Server
    URL del servidor a configurar. Sin parametro muestra el servidor actual.
.PARAMETER Reset
    Vuelve al servidor oficial de Bitwarden (vault.bitwarden.com).
.EXAMPLE
    bwconfig                                 # muestra el servidor actual
    bwconfig "https://mi-servidor.com"       # cambia el servidor
    bwconfig "https://vault.bitwarden.eu"    # servidor EU
    bwconfig -Reset                          # vuelve al servidor oficial
#>
function bwconfig {
    param(
        [Parameter(Position = 0)][string]$Server,
        [switch]$Reset
    )

    if ($Reset) {
        bw config server https://vault.bitwarden.com
        Write-Host 'OK Servidor restablecido a vault.bitwarden.com'
        Write-Host '! Recuerda hacer bwlogin de nuevo'
        return
    }

    if ($Server) {
        bw config server $Server
        Write-Host "OK Servidor configurado: $Server"
        Write-Host '! Recuerda hacer bwlogin de nuevo'
        return
    }

    $current = bw config server
    Write-Host "Servidor actual: $current"
}

<#
.SYNOPSIS
    Bloquea el vault y elimina la variable de sesion.
#>
function bwlock {
    bw lock
    Remove-Item Env:BW_SESSION -ErrorAction SilentlyContinue
}

#endregion

#region ── Internal Helpers ────────────────────────────────────────────────────

<#
.SYNOPSIS
    Helper interno. Crea una carpeta de forma interactiva.
    No llamar directamente; usar bwfolder -Add o bwadd.
#>
function _bwfolder_create {
    $fname = ''
    while (-not $fname) { $fname = Read-Host 'Folder name (required)' }

    $template = bw get template folder | ConvertFrom-Json
    $template.name = $fname
    $template | _bw_encode | bw create folder | Out-Null
    Write-Host 'OK Folder created'
}

<#
.SYNOPSIS
    Helper interno. Crea una coleccion de forma interactiva.
    No llamar directamente; usar bwcollection -Add.
#>
function _bwcollection_create {
    Write-Host 'Available organizations:'
    (bw list organizations | ConvertFrom-Json) | ForEach-Object {
        Write-Host "  $($_.id) - $($_.name)"
    }

    $orgid = Read-Host 'Organization ID'
    if (-not $orgid) { Write-Host 'X Organization ID is required'; return }

    $cname = ''
    while (-not $cname) { $cname = Read-Host 'Collection name (required)' }
    $externalid = Read-Host 'External ID (leave empty for none)'

    $template = bw get template collection | ConvertFrom-Json
    $template.organizationId = $orgid
    $template.name           = $cname
    $template.externalId     = if ($externalid) { $externalid } else { $null }

    $template | _bw_encode | bw create org-collection --organizationid $orgid | Out-Null
    Write-Host 'OK Collection created'
}

<#
.SYNOPSIS
    Helper interno. Muestra las carpetas disponibles, pide al usuario que seleccione
    una por numero y devuelve su ID. No llamar directamente.
.OUTPUTS
    [string] ID de la carpeta seleccionada, o null si el usuario no eligio ninguna.
#>
function _bwadd_select_folder {
    $folders = @(bw list folders | ConvertFrom-Json | Where-Object { $_.name -ne 'No Folder' })

    if ($folders.Count -gt 0) {
        Write-Host "`nAvailable folders:"
        for ($i = 0; $i -lt $folders.Count; $i++) {
            Write-Host "  $($i + 1)) $($folders[$i].name)"
        }
        $num = Read-Host 'Folder number (leave empty for none)'
        if ($num -match '^\d+$') {
            $idx = [int]$num - 1
            if ($idx -ge 0 -and $idx -lt $folders.Count) {
                return $folders[$idx].id
            }
        }
    }
    return $null
}

<#
.SYNOPSIS
    Helper interno. Solicita los datos de un item de tipo Login y devuelve el objeto.
.OUTPUTS
    [PSCustomObject] Sub-objeto login.
#>
function _bwadd_login {
    $uri      = Read-Host 'URL'
    $username = Read-Host 'Username'
    $password = Read-Host 'Password (leave empty to generate one)'

    if (-not $password) {
        $password = _bwgen_interactive
        Write-Host 'OK Password generated'
    }

    $login          = bw get template item.login | ConvertFrom-Json
    $login.username = $username
    $login.password = $password
    $login.uris     = if ($uri) {
                          @([PSCustomObject]@{ match = $null; uri = $uri })
                      } else { @() }
    # La plantilla incluye totp como null; eliminamos la propiedad para que
    # ConvertTo-Json no la serialice y Bitwarden no cree el campo TOTP
    $login.PSObject.Properties.Remove('totp')
    return $login
}

<#
.SYNOPSIS
    Helper interno. Solicita los datos de una tarjeta y devuelve el objeto.
.OUTPUTS
    [PSCustomObject] Sub-objeto card.
#>
function _bwadd_card {
    $card                = bw get template item.card | ConvertFrom-Json
    $card.cardholderName = Read-Host 'Cardholder name'
    $card.brand          = Read-Host 'Brand (visa/mastercard/amex/discover/diners/jcb/maestro/unionpay)'
    $card.number         = Read-Host 'Card number'
    $card.expMonth       = Read-Host 'Expiration month (01-12)'
    $card.expYear        = Read-Host 'Expiration year'
    $card.code           = Read-Host 'CVV'
    return $card
}

<#
.SYNOPSIS
    Helper interno. Solicita los datos de una identidad y devuelve el objeto.
.OUTPUTS
    [PSCustomObject] Sub-objeto identity.
#>
function _bwadd_identity {
    $id                = bw get template item.identity | ConvertFrom-Json
    $id.title          = Read-Host 'Title (Mr/Mrs/Ms/Dr)'
    $id.firstName      = Read-Host 'First name'
    $id.middleName     = Read-Host 'Middle name'
    $id.lastName       = Read-Host 'Last name'
    $id.company        = Read-Host 'Company'
    $id.email          = Read-Host 'Email'
    $id.phone          = Read-Host 'Phone'
    $id.address1       = Read-Host 'Address'
    $id.address2       = Read-Host 'Address (line 2)'
    $id.city           = Read-Host 'City'
    $id.state          = Read-Host 'State/Province'
    $id.postalCode     = Read-Host 'Postal code'
    $id.country        = Read-Host 'Country'
    $id.username       = Read-Host 'Username'
    $id.ssn            = Read-Host 'SSN'
    $id.passportNumber = Read-Host 'Passport number'
    $id.licenseNumber  = Read-Host "Driver's license number"
    return $id
}

<#
.SYNOPSIS
    Helper interno. Solicita los datos de una clave SSH y devuelve el objeto.
.OUTPUTS
    [PSCustomObject] Sub-objeto sshKey.
#>
function _bwadd_sshkey {
    [PSCustomObject]@{
        privateKey  = Read-Host 'Private key'
        publicKey   = Read-Host 'Public key'
        fingerprint = Read-Host 'Fingerprint'
    }
}

<#
.SYNOPSIS
    Helper interno. Solicita opciones de generacion de contrasena/frase de paso
    de forma interactiva y devuelve el resultado generado.
    No llamar directamente; usar bwgen o bwadd.
.OUTPUTS
    [string] Contrasena o frase de paso generada.
#>
function _bwgen_interactive {
    $type = Read-Host 'Type (password/passphrase) [password]'
    if (-not $type) { $type = 'password' }

    $genArgs = @()

    if ($type -eq 'passphrase') {
        $words = Read-Host 'Number of words [3]'
        $sep   = Read-Host 'Separator [_]'
        $cap   = Read-Host 'Capitalize? (y/n) [n]'
        $incn  = Read-Host 'Include number? (y/n) [n]'

        $genArgs += '-p', '--words', $(if ($words) { $words } else { '3' })
        $genArgs += '--separator', $(if ($sep) { $sep } else { '_' })
        if ($cap  -eq 'y') { $genArgs += '-c' }
        if ($incn -eq 'y') { $genArgs += '--includeNumber' }
    } else {
        $len    = Read-Host 'Length [25]'
        $upper  = Read-Host 'Uppercase? (y/n) [y]'
        $lower  = Read-Host 'Lowercase? (y/n) [y]'
        $nums   = Read-Host 'Numbers? (y/n) [y]'
        $spec   = Read-Host 'Special characters? (y/n) [y]'
        $amb    = Read-Host 'Avoid ambiguous? (y/n) [n]'
        $minnum = Read-Host 'Minimum numbers [0]'
        $minspc = Read-Host 'Minimum special [0]'

        $genArgs += '--length', $(if ($len) { $len } else { '25' })
        if ($upper -ne 'n') { $genArgs += '-u' }
        if ($lower -ne 'n') { $genArgs += '-l' }
        if ($nums  -ne 'n') { $genArgs += '-n' }
        if ($spec  -ne 'n') { $genArgs += '-s' }
        if ($amb   -eq 'y') { $genArgs += '--ambiguous' }
        if ($minnum -and [int]$minnum -gt 0) { $genArgs += '--minNumber',  $minnum }
        if ($minspc -and [int]$minspc -gt 0) { $genArgs += '--minSpecial', $minspc }
    }

    bw generate @genArgs
}

#endregion

#region ── Main Functions ──────────────────────────────────────────────────────

<#
.SYNOPSIS
    Lista items del vault con soporte de fzf para acciones en bloque.
.PARAMETER Folder
    ID de la carpeta para filtrar items.
.PARAMETER Trash
    Selecciona items con fzf y los mueve a la papelera.
.PARAMETER Delete
    Selecciona items con fzf y los elimina permanentemente.
.PARAMETER ListTrash
    Lista los items actualmente en la papelera.
.EXAMPLE
    bwls
    bwls -ListTrash
    bwls -Folder "folder-id"
    bwls -Trash
    bwls -Folder "folder-id" -Delete
#>
function bwls {
    param(
        [string]$Folder,
        [switch]$Trash,
        [switch]$Delete,
        [switch]$ListTrash
    )

    if ($ListTrash) {
        (bw list items --trash | ConvertFrom-Json) | ForEach-Object {
            "$($_.id) - $($_.name) - $($_.login.username)"
        }
        return
    }

    $raw = if ($Folder) {
        bw list items --folderid $Folder | ConvertFrom-Json
    } else {
        bw list items | ConvertFrom-Json
    }

    $lines = $raw | ForEach-Object { "$($_.id) $($_.name) - $($_.login.username)" }

    if ($Trash) {
        $selected = $lines | _bw_select -Multi
        if (-not $selected) { return }
        @($selected) | ForEach-Object { bw delete item ($_ -split '\s+')[0] }
        Write-Host 'OK Items moved to trash'
    } elseif ($Delete) {
        $selected = $lines | _bw_select -Multi
        if (-not $selected) { return }
        @($selected) | ForEach-Object { bw delete item ($_ -split '\s+')[0] --permanent }
        Write-Host 'OK Items permanently deleted'
    } else {
        # Quita el ID del principio y ordena
        $lines | ForEach-Object { $_ -replace '^\S+\s+', '' } | Sort-Object
    }
}

<#
.SYNOPSIS
    Busca items por nombre, usuario o URL con soporte para acciones.
    Los filtros son combinables entre si.
.PARAMETER Name
    Filtra por nombre (insensible a mayusculas, coincidencia parcial).
.PARAMETER User
    Filtra por nombre de usuario exacto.
.PARAMETER Url
    Filtra por URL (coincidencia parcial).
.PARAMETER Show
    Muestra campos del item. Sin -Field muestra todos los relevantes.
    Con -Field attachment lista los adjuntos del item.
.PARAMETER Copy
    Copia un campo al portapapeles. Sin -Field copia la contrasena.
    Con -Field attachment descarga un adjunto (requiere -AttachmentName).
.PARAMETER Field
    Campo a mostrar o copiar. Usado junto a -Show o -Copy.
.PARAMETER AttachmentName
    Nombre del adjunto a descargar.
.PARAMETER AttachmentOutput
    Ruta de destino para el adjunto descargado.
.PARAMETER Exposed
    Comprueba si la contrasena aparece en brechas de seguridad conocidas.
.PARAMETER Trash
    Selecciona items con fzf y los mueve a la papelera.
.PARAMETER Delete
    Selecciona items con fzf y los elimina permanentemente.
.EXAMPLE
    bwfind -Name "github"
    bwfind -Name "github" -User "me@mail.com"
    bwfind -Name "github" -Show
    bwfind -Name "github" -Show -Field password
    bwfind -Name "github" -Show -Field attachment
    bwfind -Name "github" -Copy
    bwfind -Name "github" -Copy -Field username
    bwfind -Name "github" -Copy -Field attachment -AttachmentName "key.pem" -AttachmentOutput "~/keys/"
    bwfind -Name "github" -Exposed
    bwfind -Name "github" -Trash
#>
function bwfind {
    param(
        [string]$Name,
        [string]$User,
        [string]$Url,
        [switch]$Show,
        [switch]$Copy,
        [string]$Field,
        [string]$AttachmentName,
        [string]$AttachmentOutput,
        [switch]$Exposed,
        [switch]$Trash,
        [switch]$Delete
    )

    if (-not $Name -and -not $User -and -not $Url) {
        Write-Host 'X You must specify at least one filter: -Name, -User or -Url'
        return
    }

    $items = bw list items | ConvertFrom-Json

    if ($Name) { $items = $items | Where-Object { $_.name -like "*$Name*" } }
    if ($User) { $items = $items | Where-Object { $_.login.username -eq $User } }
    if ($Url)  { $items = $items | Where-Object { $_.login.uris -and ($_.login.uris | Where-Object { $_.uri -like "*$Url*" }) } }

    if (-not $items) { Write-Host 'X No items found'; return }

    $results = @($items | ForEach-Object { "$($_.id) $($_.name) - $($_.login.username)" })

    # Selecciona un item: directo si solo hay uno, fzf si hay varios
    $selectItem = {
        if ($results.Count -eq 1) {
            ($results[0] -split '\s+')[0]
        } else {
            $sel = $results | _bw_select
            if ($sel) { ($sel -split '\s+')[0] }
        }
    }

    if ($Show) {
        $id = & $selectItem
        if (-not $id) { return }

        if (-not $Field) {
            $i = bw get item $id | ConvertFrom-Json
            [PSCustomObject]@{
                id       = $i.id
                name     = $i.name
                username = $i.login.username
                password = $i.login.password
                uris     = @($i.login.uris | ForEach-Object { $_.uri })
                totp     = $i.login.totp
                notes    = $i.notes
            } | _bw_pretty
        } elseif ($Field -eq 'attachment') {
            (bw get item $id | ConvertFrom-Json).attachments | ForEach-Object {
                "$($_.id) - $($_.fileName) - $($_.sizeName)"
            }
        } else {
            bw get $Field $id
        }
    } elseif ($Copy) {
        $id = & $selectItem
        if (-not $id) { return }

        $copyField = if ($Field) { $Field } else { 'password' }

        if ($copyField -eq 'attachment') {
            if (-not $AttachmentName) { Write-Host 'X You must specify -AttachmentName'; return }
            $bwArgs = @('get', 'attachment', $AttachmentName, '--itemid', $id)
            if ($AttachmentOutput) { $bwArgs += '--output', $AttachmentOutput }
            & bw @bwArgs
            Write-Host 'OK Attachment downloaded'
        } else {
            $value = bw get $copyField $id
            Set-Clipboard $value
            Write-Host "OK $copyField copied to clipboard"
        }
    } elseif ($Exposed) {
        $id = & $selectItem
        if (-not $id) { return }
        $count = [int](bw get exposed $id)
        if ($count -gt 0) {
            Write-Host "!! Password found in $count security breaches"
        } else {
            Write-Host 'OK Password not found in any security breach'
        }
    } elseif ($Trash) {
        $selected = $results | _bw_select -Multi
        if (-not $selected) { return }
        @($selected) | ForEach-Object { bw delete item ($_ -split '\s+')[0] }
        Write-Host 'OK Items moved to trash'
    } elseif ($Delete) {
        $selected = $results | _bw_select -Multi
        if (-not $selected) { return }
        @($selected) | ForEach-Object { bw delete item ($_ -split '\s+')[0] --permanent }
        Write-Host 'OK Items permanently deleted'
    } else {
        $results | Sort-Object
    }
}

<#
.SYNOPSIS
    Muestra los detalles completos de un item por su ID en JSON legible.
.PARAMETER Id
    ID del item a mostrar.
.EXAMPLE
    bwitem "item-id"
#>
function bwitem {
    param([Parameter(Mandatory)][string]$Id)
    bw get item $Id | ConvertFrom-Json | _bw_pretty
}

<#
.SYNOPSIS
    Edita un item, carpeta, coleccion o las colecciones de un item de forma interactiva.
    Muestra los valores actuales como predeterminados; dejar vacio conserva el valor actual.
.PARAMETER Type
    Tipo de objeto a editar: item, folder, org-collection, item-collections.
.PARAMETER Id
    ID del objeto a editar.
.EXAMPLE
    bwedit item "id"
    bwedit folder "id"
    bwedit org-collection "id"
    bwedit item-collections "id"
#>
function bwedit {
    param(
        [Parameter(Mandatory)][ValidateSet('item','folder','org-collection','item-collections')]
        [string]$Type,
        [Parameter(Mandatory)][string]$Id
    )

    switch ($Type) {
        'item' {
            $current = bw get item $Id | ConvertFrom-Json
            $curName = $current.name
            $curUser = $current.login.username
            $curPass = $current.login.password
            $curUri  = if ($current.login.uris -and $current.login.uris.Count -gt 0) {
                           $current.login.uris[0].uri
                       } else { '' }
            $curNote = $current.notes

            $name     = Read-Host "Name [$curName]"
            $username = Read-Host "Username [$curUser]"
            $password = Read-Host 'Password (leave empty to keep, "gen" to generate)'
            $uri      = Read-Host "URL [$curUri]"
            $notes    = Read-Host 'Notes (leave empty to keep)'

            if (-not $password)          { $password = $curPass }
            elseif ($password -eq 'gen') {
                $password = _bwgen_interactive
                Write-Host "OK Password generated: $password"
            }

            if (-not $name)     { $name     = $curName }
            if (-not $username) { $username = $curUser }
            if (-not $uri)      { $uri      = $curUri  }
            if (-not $notes)    { $notes    = $curNote }

            $current.name              = $name
            $current.login.username    = $username
            $current.login.password    = $password
            $current.login.uris[0].uri = $uri
            $current.notes             = $notes

            # Custom fields
            if ($current.fields -and $current.fields.Count -gt 0) {
                Write-Host "Custom fields:"
                foreach ($f in $current.fields) {
                    Write-Host "  [$($f.name)] = $($f.value)"
                    Write-Host "  New value for '$($f.name)' (leave empty to keep): " -NoNewline
                    $newVal = [Console]::ReadLine()
                    if ($newVal) { $f.value = $newVal }
                }
            }
            while ($true) {
                Write-Host "Add new field? (name=value, leave empty to finish): " -NoNewline
                $newField = [Console]::ReadLine()
                if (-not $newField) { break }
                if ($newField -match '^(.+)=(.+)$') {
                    $current.fields += [pscustomobject]@{
                        name  = $Matches[1].Trim()
                        value = $Matches[2].Trim()
                        type  = 0
                    }
                } else {
                    Write-Host 'X Invalid format, use name=value'
                }
            }

            $current | _bw_encode | bw edit item $Id | Out-Null
            Write-Host 'OK Item updated successfully'
        }

        'folder' {
            $folder = bw get folder $Id | ConvertFrom-Json
            $fname  = Read-Host "Folder name [$($folder.name)]"
            if (-not $fname) { $fname = $folder.name }
            $folder.name = $fname
            $folder | _bw_encode | bw edit folder $Id | Out-Null
            Write-Host 'OK Folder renamed successfully'
        }

        'org-collection' {
            Write-Host 'Available organizations:'
            (bw list organizations | ConvertFrom-Json) | ForEach-Object {
                Write-Host "  $($_.id) - $($_.name)"
            }
            $orgid = Read-Host 'Organization ID'
            if (-not $orgid) { Write-Host 'X Organization ID is required'; return }

            $coll  = bw get org-collection $Id --organizationid $orgid | ConvertFrom-Json
            $cname = Read-Host "Collection name [$($coll.name)]"
            if (-not $cname) { $cname = $coll.name }
            $coll.name = $cname
            $coll | _bw_encode | bw edit org-collection $Id --organizationid $orgid | Out-Null
            Write-Host 'OK Collection renamed successfully'
        }

        'item-collections' {
            Write-Host 'Available collections:'
            (bw list org-collections | ConvertFrom-Json) | ForEach-Object {
                Write-Host "  $($_.id) - $($_.name)"
            }
            $collectionids = Read-Host 'Enter collection IDs separated by spaces'
            $idsArray = @($collectionids -split '\s+' | Where-Object { $_ })
            ($idsArray | ConvertTo-Json -AsArray) | bw encode | bw edit item-collections $Id | Out-Null
            Write-Host 'OK Item collections updated successfully'
        }
    }
}

<#
.SYNOPSIS
    Mueve un item a una carpeta diferente de forma interactiva o directa.
.PARAMETER ItemId
    ID del item a mover.
.PARAMETER FolderId
    ID de la carpeta de destino. Si se omite, se selecciona con fzf.
.EXAMPLE
    bwmv "item-id"
    bwmv "item-id" "folder-id"
#>
function bwmv {
    param(
        [Parameter(Mandatory)][string]$ItemId,
        [string]$FolderId
    )

    if (-not $FolderId) {
        $folders = bw list folders | ConvertFrom-Json | Where-Object { $_.name -ne 'No Folder' }
        $sel     = ($folders | ForEach-Object { "$($_.id) $($_.name)" }) | _bw_select
        if (-not $sel) { return }
        $FolderId = ($sel -split '\s+')[0]
    }

    $item = bw get item $ItemId | ConvertFrom-Json
    $item.folderId = $FolderId
    $item | _bw_encode | bw edit item $ItemId | Out-Null
    Write-Host 'OK Item moved successfully'
}

<#
.SYNOPSIS
    Gestiona adjuntos del vault.
.PARAMETER All
    Lista todos los adjuntos de todos los items.
.PARAMETER ItemId
    ID del item cuyos adjuntos se gestionan.
.PARAMETER Name
    Nombre del adjunto a descargar.
.PARAMETER Output
    Ruta de destino para la descarga del adjunto.
.PARAMETER File
    Ruta del fichero local a adjuntar (usado con -Add).
.PARAMETER Add
    Adjunta el fichero especificado en -File al item indicado en -ItemId.
.EXAMPLE
    bwattachment -All
    bwattachment -ItemId "id"
    bwattachment -Add -File "~/photo.jpg" -ItemId "id"
    bwattachment -Name "photo.jpg" -ItemId "id"
    bwattachment -Name "photo.jpg" -ItemId "id" -Output "~/downloads/"
#>
function bwattachment {
    param(
        [Alias('a')][switch]$All,
        [string]$ItemId,
        [string]$Name,
        [string]$Output,
        [string]$File,
        [switch]$Add
    )

    if ($All) {
        (bw list items | ConvertFrom-Json) | Where-Object { $_.attachments } | ForEach-Object {
            $itemName = $_.name
            $_.attachments | ForEach-Object {
                "$itemName - $($_.id) - $($_.fileName) - $($_.sizeName)"
            }
        }
        return
    }

    if (-not $ItemId) { Write-Host 'X You must specify -ItemId'; return }

    if ($Add) {
        if (-not $File) { Write-Host 'X You must specify -File'; return }
        bw create attachment --file $File --itemid $ItemId
        Write-Host 'OK Attachment added'
    } elseif ($Name) {
        $bwArgs = @('get', 'attachment', $Name, '--itemid', $ItemId)
        if ($Output) { $bwArgs += '--output', $Output }
        & bw @bwArgs
        Write-Host 'OK Attachment downloaded'
    } else {
        (bw get item $ItemId | ConvertFrom-Json).attachments | ForEach-Object {
            "$($_.id) - $($_.fileName) - $($_.sizeName)"
        }
    }
}

<#
.SYNOPSIS
    Gestiona las carpetas del vault.
.PARAMETER All
    Lista todas las carpetas.
.PARAMETER Id
    ID de la carpeta a mostrar o eliminar directamente.
.PARAMETER Add
    Crea una carpeta de forma interactiva.
.PARAMETER Delete
    Elimina la carpeta. Si no se especifica -Id, selecciona con fzf.
.EXAMPLE
    bwfolder -All
    bwfolder -Id "folder-id"
    bwfolder -Add
    bwfolder -Delete
    bwfolder -Id "folder-id" -Delete
#>
function bwfolder {
    param(
        [Alias('a')][switch]$All,
        [string]$Id,
        [switch]$Add,
        [switch]$Delete
    )

    if ($All) {
        (bw list folders | ConvertFrom-Json) | Where-Object { $_.name -ne 'No Folder' } | ForEach-Object {
            "$($_.id) - $($_.name)"
        }
        return
    }
    if ($Add) { _bwfolder_create; return }
    if ($Delete) {
        if (-not $Id) {
            $folders = (bw list folders | ConvertFrom-Json) | Where-Object { $_.name -ne 'No Folder' }
            $sel     = ($folders | ForEach-Object { "$($_.id) $($_.name)" }) | _bw_select
            if (-not $sel) { return }
            $Id = ($sel -split '\s+')[0]
        }
        bw delete folder $Id
        Write-Host 'OK Folder deleted'
        return
    }

    if (-not $Id) { Write-Host 'X You must specify an ID, -All, -Add, or -Delete'; return }
    bw get folder $Id | ConvertFrom-Json | _bw_pretty
}

<#
.SYNOPSIS
    Gestiona las colecciones de la organizacion.
.PARAMETER All
    Lista todas las colecciones.
.PARAMETER Id
    ID de la coleccion a mostrar.
.PARAMETER Add
    Crea una coleccion de forma interactiva.
.EXAMPLE
    bwcollection -All
    bwcollection -Id "collection-id"
    bwcollection -Add
#>
function bwcollection {
    param(
        [Alias('a')][switch]$All,
        [string]$Id,
        [switch]$Add
    )

    if ($All)  { (bw list org-collections | ConvertFrom-Json) | ForEach-Object { "$($_.id) - $($_.name)" }; return }
    if ($Add)  { _bwcollection_create; return }
    if (-not $Id) { Write-Host 'X You must specify an ID, -All, or -Add'; return }
    bw get org-collection $Id | ConvertFrom-Json | _bw_pretty
}

<#
.SYNOPSIS
    Muestra las plantillas disponibles del vault.
.PARAMETER All
    Lista todas las plantillas disponibles.
.PARAMETER Name
    Nombre de la plantilla a mostrar.
.EXAMPLE
    bwtemplate -All
    bwtemplate -Name item.login
#>
function bwtemplate {
    param(
        [Alias('a')][switch]$All,
        [string]$Name
    )

    $validTemplates = @(
        'item','item.field','item.login','item.login.uri','item.card',
        'item.identity','item.securenote','folder','collection',
        'item-collections','org-collection'
    )

    if ($All) {
        Write-Host 'Available templates:'
        $validTemplates | ForEach-Object { Write-Host "  - $_" }
        return
    }
    if (-not $Name) { Write-Host 'X You must specify a template name or -All'; return }
    bw get template $Name | ConvertFrom-Json | _bw_pretty
}

<#
.SYNOPSIS
    Anade un nuevo item o carpeta de forma interactiva.
    Soporta todos los tipos: login, securenote, card, identity, sshkey, folder.
.EXAMPLE
    bwadd
#>
function bwadd {
    Write-Host 'Available types:'
    Write-Host '  1) Login'
    Write-Host '  2) Secure Note'
    Write-Host '  3) Card'
    Write-Host '  4) Identity'
    Write-Host '  5) SSH Key'
    Write-Host '  6) Folder'

    $type = Read-Host 'Type [1]'
    if (-not $type) { $type = '1' }

    if ($type -eq '6') { _bwfolder_create; return }

    $name = ''
    while (-not $name) { $name = Read-Host 'Item name (required)' }
    $notes = Read-Host 'Notes'

    $item       = bw get template item | ConvertFrom-Json
    $item.type  = [int]$type
    $item.name  = $name
    $item.notes = $notes

    switch ($type) {
        '1' { $item.login      = _bwadd_login }
        '2' { $item.secureNote = bw get template item.securenote | ConvertFrom-Json }
        '3' { $item.card       = _bwadd_card }
        '4' { $item.identity   = _bwadd_identity }
        '5' { $item.sshKey     = _bwadd_sshkey }
        default { Write-Host 'X Invalid type'; return }
    }

    $folderid = _bwadd_select_folder
    if ($folderid) { $item.folderId = $folderid }

    # Custom fields
    $item.fields = @()
    while ($true) {
        Write-Host "Add field? (name=value, leave empty to finish): " -NoNewline
        $newField = [Console]::ReadLine()
        if (-not $newField) { break }
        if ($newField -match '^(.+)=(.+)$') {
            $item.fields += [pscustomobject]@{
                name  = $Matches[1].Trim()
                value = $Matches[2].Trim()
                type  = 0
            }
        } else {
            Write-Host 'X Invalid format, use name=value'
        }
    }

    $output = $item | _bw_encode | bw create item 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host 'OK Item created successfully'
    } else {
        Write-Host "X Error creating item: $output"
    }
}

<#
.SYNOPSIS
    Genera una contrasena o frase de paso de forma interactiva y la copia al portapapeles.
.EXAMPLE
    bwgen
#>
function bwgen {
    $generated = _bwgen_interactive
    Set-Clipboard $generated
    Write-Host "OK Password generated and copied: $generated"
}

<#
.SYNOPSIS
    Mueve un item a la papelera por su ID (se elimina automaticamente tras 30 dias).
.PARAMETER Id
    ID del item a enviar a la papelera.
.EXAMPLE
    bwtrash "item-id"
#>
function bwtrash {
    param([Parameter(Mandatory)][string]$Id)
    bw delete item $Id
    Write-Host 'OK Item moved to trash'
}

<#
.SYNOPSIS
    Elimina permanentemente un item o carpeta por su ID.
.PARAMETER Type
    Tipo de objeto: 'item' (predeterminado) o 'folder'.
.PARAMETER Id
    ID del objeto a eliminar.
.EXAMPLE
    bwdelete "item-id"
    bwdelete item "item-id"
    bwdelete folder "folder-id"
#>
function bwdelete {
    param(
        [string]$Type = 'item',
        [Parameter(Mandatory)][string]$Id
    )

    if ($Type -eq 'folder') {
        bw delete folder $Id
        Write-Host 'OK Folder deleted'
    } else {
        bw delete item $Id --permanent
        Write-Host 'OK Item permanently deleted'
    }
}

<#
.SYNOPSIS
    Vacia la papelera eliminando permanentemente todos sus items.
.EXAMPLE
    bwempty
#>
function bwempty {
    (bw list items --trash | ConvertFrom-Json) | ForEach-Object {
        bw delete item $_.id --permanent
    }
    Write-Host 'OK Trash emptied'
}

<#
.SYNOPSIS
    Restaura un item de la papelera antes de que sea eliminado automaticamente.
.PARAMETER Id
    ID del item a restaurar.
.EXAMPLE
    bwrestore "item-id"
#>
function bwrestore {
    param([Parameter(Mandatory)][string]$Id)
    bw restore item $Id
    Write-Host 'OK Item restored'
}

#endregion
