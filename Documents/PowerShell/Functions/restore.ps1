# restore.ps1
$SourceDir = chezmoi source-path
$PackagesDir = Join-Path $SourceDir "packages\windows"
$HerdrPluginsFile = Join-Path $SourceDir "packages\windows\herdr-plugins.json"

# -- fzf selection helpers -----------------------------------------------------
# Multi-select: TAB=toggle (no cursor move)  CTRL-A=toggle-all  ENTER=confirm  ESC=skip
function Select-WithFzf {
    param(
        [string[]]$Items,
        [string]$Prompt = "Select>",
        [string]$Header = "TAB=toggle  CTRL-A=toggle-all  ENTER=confirm  ESC=skip"
    )
    if (-not $Items -or $Items.Count -eq 0) { return @() }
    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
        Write-Host "  [WARN] fzf not found - selecting all $($Items.Count) items" -ForegroundColor Yellow
        return $Items
    }
    $selected = $Items | fzf --multi --prompt="  $Prompt " --header="$Header" `
        --layout=reverse --border --bind='ctrl-a:toggle-all' --bind='tab:toggle'
    if ($LASTEXITCODE -ne 0) { return @() }
    return @($selected | Where-Object { $_ })
}

# Single-select: ENTER=confirm  ESC=skip
function Select-OneFzf {
    param(
        [string[]]$Items,
        [string]$Prompt = "Select>",
        [string]$Header = "ENTER=confirm  ESC=skip"
    )
    if (-not $Items -or $Items.Count -eq 0) { return $null }
    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) { return $Items[0] }
    $selected = $Items | fzf --prompt="  $Prompt " --header="$Header" `
        --layout=reverse --border
    if ($LASTEXITCODE -ne 0) { return $null }
    return $selected
}

# -- Invoke-AllRestore ---------------------------------------------------------
function Invoke-AllRestore {
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [ValidateSet('winget', 'winget-elevated', 'scoop', 'mise', 'herdr')]
        [string[]]$Manager,
        [string[]]$Plugin,
        [switch]$All,
        [switch]$Yes
    )
    if (($Plugin -or $All -or $Yes) -and (-not $Manager -or ($Manager -ne 'herdr'))) {
        throw 'Plugin selection arguments require -Manager herdr only.'
    }

    $selectedManagers = $Manager
    if (-not $selectedManagers) {
        $pkgDir = $PackagesDir
        $candidates = [System.Collections.Generic.List[string]]::new()
        if ((Test-Path "$pkgDir\winget\packages.json") -or (Test-Path "$pkgDir\winget\minimal.json")) {
            $candidates.Add("winget")
        }
        if (Test-Path "$pkgDir\winget\elevated.json") { $candidates.Add("winget-elevated") }
        if (Test-Path "$pkgDir\scoop\packages.json") { $candidates.Add("scoop") }
        if (Get-Command mise -ErrorAction SilentlyContinue) { $candidates.Add("mise") }
        if ((Test-Path $HerdrPluginsFile) -and (Get-Command herdr -ErrorAction SilentlyContinue)) { $candidates.Add("herdr") }

        $selectedManagers = Select-WithFzf $candidates.ToArray() "Package managers>" `
            "TAB=toggle  CTRL-A=all  ENTER=confirm  ESC=skip all"
    }

    if (-not $selectedManagers -or $selectedManagers.Count -eq 0) {
        Write-Host "No managers selected." -ForegroundColor Yellow
        return
    }

    if ($selectedManagers -contains "winget") { Invoke-WingetRestore }
    if ($selectedManagers -contains "winget-elevated") { Invoke-WingetElevatedRestore }
    if ($selectedManagers -contains "scoop") { Invoke-ScoopRestore }
    if ($selectedManagers -contains "mise") { Invoke-MiseRestore }
    if ($selectedManagers -contains "herdr") { Invoke-HerdrRestore -Plugin $Plugin -All:$All -Yes:$Yes }

    Write-Host "Restore completado" -ForegroundColor Green
}
Set-Alias -Name restore      -Value Invoke-AllRestore
Set-Alias -Name restore-pkgs -Value Invoke-AllRestore

# -- winget --------------------------------------------------------------------
function Invoke-WingetRestore {
    $pkgDir = $PackagesDir

    $wingetProfiles = @()
    if (Test-Path "$pkgDir\winget\minimal.json") { $wingetProfiles += "minimal" }
    if (Test-Path "$pkgDir\winget\packages.json") { $wingetProfiles += "full" }

    $profileChoice = Select-WithFzf $wingetProfiles "winget profile>" `
        "Select package profile: minimal=dotfiles only  full=everything"
    $wingetFile = if ($profileChoice -contains "minimal") {
        "$pkgDir\winget\minimal.json"
    }
    else {
        "$pkgDir\winget\packages.json"
    }

    if (-not (Test-Path $wingetFile)) {
        Write-Warning "No encontrado: $wingetFile"
        return
    }

    Write-Host "  Profile: $(Split-Path $wingetFile -Leaf)" -ForegroundColor Cyan

    $wingetJson = Get-Content $wingetFile | ConvertFrom-Json
    $allIds = @($wingetJson.Sources | ForEach-Object { $_.Packages } |
            Select-Object -ExpandProperty PackageIdentifier | Sort-Object)

    $selectedIds = Select-WithFzf $allIds "winget>"
    foreach ($id in $selectedIds) {
        $installed = winget list --id $id --accept-source-agreements 2>$null | Select-String $id
        if ($installed) {
            Write-Host "  [SKIP] $id already installed" -ForegroundColor DarkGray
        }
        else {
            Write-Host "  [....] $id" -ForegroundColor Cyan
            winget install --id $id --accept-package-agreements --accept-source-agreements -e
        }
    }
    Write-Host "winget restore OK" -ForegroundColor Green
}
Set-Alias -Name restore-winget -Value Invoke-WingetRestore

# -- winget (elevated) ---------------------------------------------------------
function Invoke-WingetElevatedRestore {
    $file = "$PackagesDir\winget\elevated.json"
    if (-not (Test-Path $file)) { Write-Warning "No encontrado: $file"; return }

    $allIds = @((Get-Content $file | ConvertFrom-Json).Sources |
            ForEach-Object { $_.Packages } | Select-Object -ExpandProperty PackageIdentifier | Sort-Object)

    $selectedIds = Select-WithFzf $allIds "winget-elevated>"
    foreach ($id in $selectedIds) {
        $installed = winget list --id $id --accept-source-agreements 2>$null | Select-String $id
        if ($installed) {
            Write-Host "  [SKIP] $id already installed" -ForegroundColor DarkGray
        }
        else {
            Write-Host "  [....] $id (elevated)" -ForegroundColor Cyan
            $tmpScript = "$env:TEMP\winget-elevated-$id.ps1"
            "winget install --id $id --accept-package-agreements --accept-source-agreements -e" |
                Set-Content $tmpScript
            Start-Process powershell.exe -Verb RunAs -WindowStyle Hidden -ArgumentList "-NoProfile", "-File", $tmpScript -Wait
            Remove-Item $tmpScript -ErrorAction SilentlyContinue
        }
    }
    Write-Host "winget-elevated restore OK" -ForegroundColor Green
}
Set-Alias -Name restore-winget-elevated -Value Invoke-WingetElevatedRestore

# -- scoop ---------------------------------------------------------------------
function Invoke-ScoopRestore {
    $pkgDir = $PackagesDir

    $scoopProfiles = @()
    if (Test-Path "$pkgDir\scoop\minimal.json") { $scoopProfiles += "minimal" }
    if (Test-Path "$pkgDir\scoop\packages.json") { $scoopProfiles += "full" }

    $profileChoice = Select-WithFzf $scoopProfiles "scoop profile>" `
        "Select package profile: minimal=essential tools  full=everything"
    $file = if ($profileChoice -contains "minimal") {
        "$pkgDir\scoop\minimal.json"
    }
    else {
        "$pkgDir\scoop\packages.json"
    }

    if (-not (Test-Path $file)) { Write-Warning "No encontrado: $file"; return }

    Write-Host "  Profile: $(Split-Path $file -Leaf)" -ForegroundColor Cyan

    $data = Get-Content $file | ConvertFrom-Json

    $existingBuckets = @(scoop bucket list | Select-Object -ExpandProperty Name)
    $data.buckets | ForEach-Object {
        if ($existingBuckets -notcontains $_.Name) {
            Write-Host "  Añadiendo bucket: $($_.Name)"
            scoop bucket add $_.Name $_.Source
        }
    }

    $allNames = @($data.apps | Select-Object -ExpandProperty Name | Sort-Object)
    $selectedNames = Select-WithFzf $allNames "scoop>"
    $installed = scoop list 2>$null | Select-Object -ExpandProperty Name

    foreach ($name in $selectedNames) {
        if ($installed -contains $name) {
            Write-Host "  [SKIP] $name already installed" -ForegroundColor DarkGray
        }
        else {
            $app = $data.apps | Where-Object { $_.Name -eq $name }
            Write-Host "  [....] $name" -ForegroundColor Cyan
            scoop install "$($app.Source)/$name"
        }
    }
    Write-Host "scoop restore OK" -ForegroundColor Green
}
Set-Alias -Name restore-scoop -Value Invoke-ScoopRestore

# -- mise ----------------------------------------------------------------------
function Invoke-MiseRestore {
    if (-not (Get-Command mise -ErrorAction SilentlyContinue)) { Write-Warning "mise not found."; return }
    mise trust --all
    mise install
    if ($LASTEXITCODE -ne 0) { Write-Warning "mise install failed (exit code $LASTEXITCODE)." ; return }
    Write-Host "mise restore OK" -ForegroundColor Green
}
Set-Alias -Name restore-mise -Value Invoke-MiseRestore

# -- herdr ---------------------------------------------------------------------
function Invoke-HerdrRestore {
    param([Alias('Plugin')][string[]]$PluginId, [switch]$All, [switch]$Yes)
    if ($All -and $PluginId) { throw 'Use either -All or -Plugin, not both.' }
    if (($All -or $PluginId) -and -not $Yes) { throw 'Non-interactive Herdr restore requires -Yes to trust selected plugins.' }
    if (-not (Test-Path $HerdrPluginsFile)) { Write-Warning "No encontrado: $HerdrPluginsFile"; return }
    if (-not (Get-Command herdr -ErrorAction SilentlyContinue)) { Write-Warning "Herdr no está instalado"; return }
    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) { Write-Warning "Herdr restore requiere fzf para elegir plugins"; return }

    $plugins = Get-Content $HerdrPluginsFile -Raw | ConvertFrom-Json
    $ids = @()
    foreach ($plugin in $plugins) {
        $parts = @($plugin.source -split '/')
        if ($plugin.id -isnot [string] -or $plugin.id -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$' -or
            $plugin.enabled -isnot [bool] -or $plugin.kind -notin @('github', 'local') -or
            $plugin.source -isnot [string] -or [string]::IsNullOrWhiteSpace($plugin.source) -or
            ($null -ne $plugin.ref -and ($plugin.ref -isnot [string] -or [string]::IsNullOrWhiteSpace($plugin.ref)))) {
            throw "Inventario Herdr inválido: $HerdrPluginsFile"
        }
        if ($plugin.kind -eq 'github' -and
            ($plugin.source -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_./-]+$' -or
             @($parts | Where-Object { $_ -in @('', '.', '..') }).Count -gt 0)) {
            throw "Origen GitHub inválido para $($plugin.id)"
        }
        if ($plugin.kind -eq 'local' -and
            ([System.IO.Path]::IsPathRooted($plugin.source) -or
             $plugin.source -match '(^|[\\/])\.\.?([\\/]|$)')) {
            throw "Ruta local inválida para $($plugin.id)"
        }
        $ids += $plugin.id
    }
    if (@($ids | Sort-Object -Unique).Count -ne $ids.Count) { throw "IDs Herdr duplicados en $HerdrPluginsFile" }

    if ($All) {
        $selected = $ids
    }
    elseif ($PluginId) {
        $selected = @($PluginId | Select-Object -Unique)
        $unknown = @($selected | Where-Object { $_ -notin $ids })
        if ($unknown) { throw "Plugins no encontrados en el inventario: $($unknown -join ', ')" }
    }
    else {
        $selected = Select-WithFzf $ids "Herdr plugins>"
    }
    if (-not $selected) { return }

    $live = herdr plugin list --json | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0 -or $live.result.plugins -isnot [array]) { throw "No se pudo leer el registro de plugins Herdr" }

    foreach ($id in $selected) {
        $plugin = $plugins | Where-Object id -eq $id | Select-Object -First 1
        $existing = $live.result.plugins | Where-Object plugin_id -eq $id | Select-Object -First 1
        if ($existing) {
            if ($null -ne $existing.warnings -and @($existing.warnings).Count -gt 0) { throw "$id tiene avisos en Herdr; revísalos antes de restaurar" }
            Write-Host "  [SKIP] $id ya registrado" -ForegroundColor DarkGray
            continue
        }

        if ($plugin.kind -eq 'local') {
            $path = Join-Path $HOME $plugin.source
            if (-not (Test-Path (Join-Path $path 'herdr-plugin.toml'))) { throw "${id}: falta el manifiesto local en $path" }
            if (-not $Yes -and (Read-Host "Confiar y enlazar $id? [y/N]") -notmatch '^(y|yes)$') { continue }
            $linkArgs = @('plugin', 'link', $path)
            if (-not $plugin.enabled) { $linkArgs += '--disabled' }
            & herdr @linkArgs
        }
        else {
            $installArgs = @('plugin', 'install', $plugin.source)
            if ($plugin.ref) { $installArgs += @('--ref', $plugin.ref) }
            if ($Yes) { $installArgs += '--yes' }
            & herdr @installArgs
        }
        if ($LASTEXITCODE -ne 0) { throw "Falló la instalación de $id (exit $LASTEXITCODE)" }
        if ($plugin.kind -eq 'github' -and -not $plugin.enabled) {
            & herdr plugin disable $id
            if ($LASTEXITCODE -ne 0) { throw "Falló la desactivación de $id (exit $LASTEXITCODE)" }
        }
    }
}
Set-Alias -Name restore-herdr -Value Invoke-HerdrRestore

