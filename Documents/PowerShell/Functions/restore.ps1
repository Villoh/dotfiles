# restore.ps1
$PackagesDir = "$env:USERPROFILE\.local\share\chezmoi\packages\windows"

# -- fzf selection helper ------------------------------------------------------
function Select-WithFzf {
    param(
        [string[]]$Items,
        [string]$Prompt = "Select>",
        [string]$Header = "TAB=toggle  CTRL-A=all  ENTER=confirm  ESC=skip",
        [switch]$AllowNew
    )
    if (-not $Items -or $Items.Count -eq 0) { return @() }
    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
        Write-Host "  [WARN] fzf not found - selecting all $($Items.Count) items" -ForegroundColor Yellow
        return $Items
    }
    $selected = $Items | fzf --multi --prompt="  $Prompt " --header="$Header" `
        --layout=reverse --border --bind='ctrl-a:select-all'
    if ($LASTEXITCODE -ne 0) { return @() }
    $selected = @($selected)
    if ($AllowNew) {
        $extra = Read-Host "  Add extra packages (space-separated, empty to skip)"
        if ($extra.Trim()) { $selected += $extra.Trim() -split '\s+' }
    }
    return $selected
}

# -- Invoke-AllRestore ---------------------------------------------------------
function Invoke-AllRestore {
    $pkgDir = $PackagesDir

    $candidates = [System.Collections.Generic.List[string]]::new()
    if (Test-Path "$pkgDir\winget\packages.json" -or Test-Path "$pkgDir\winget\minimal.json") {
        $candidates.Add("winget")
    }
    if (Test-Path "$pkgDir\winget\elevated.json") { $candidates.Add("winget-elevated") }
    if (Test-Path "$pkgDir\scoop\packages.json")    { $candidates.Add("scoop") }
    if (Test-Path "$pkgDir\node\npm-packages.json") { $candidates.Add("npm") }
    if (Test-Path "$pkgDir\node\bun-packages.txt")  { $candidates.Add("bun") }
    if (Test-Path "$pkgDir\uv-tools.txt")           { $candidates.Add("uv") }
    if (Test-Path "$pkgDir\bin-packages.txt")       { $candidates.Add("bin") }

    $selectedManagers = Select-WithFzf $candidates.ToArray() "Package managers>" `
        "TAB=toggle  CTRL-A=all  ENTER=confirm  ESC=skip all"

    if (-not $selectedManagers -or $selectedManagers.Count -eq 0) {
        Write-Host "No managers selected." -ForegroundColor Yellow
        return
    }

    if ($selectedManagers -contains "winget")          { Invoke-WingetRestore }
    if ($selectedManagers -contains "winget-elevated") { Invoke-WingetElevatedRestore }
    if ($selectedManagers -contains "scoop")           { Invoke-ScoopRestore }
    if ($selectedManagers -contains "npm")     { Invoke-NodeRestore }
    if ($selectedManagers -contains "bun")     { Invoke-BunRestore }
    if ($selectedManagers -contains "uv")      { Invoke-UvRestore }
    if ($selectedManagers -contains "bin")     { Invoke-BinRestore }

    Write-Host "Restore completado" -ForegroundColor Green
}
Set-Alias -Name restore      -Value Invoke-AllRestore
Set-Alias -Name restore-pkgs -Value Invoke-AllRestore

# -- winget --------------------------------------------------------------------
function Invoke-WingetRestore {
    $pkgDir = $PackagesDir

    $wingetProfiles = @()
    if (Test-Path "$pkgDir\winget\minimal.json")  { $wingetProfiles += "minimal" }
    if (Test-Path "$pkgDir\winget\packages.json") { $wingetProfiles += "full" }

    $profileChoice = Select-WithFzf $wingetProfiles "winget profile>" `
        "Select package profile: minimal=dotfiles only  full=everything"
    $wingetFile = if ($profileChoice -contains "minimal") {
        "$pkgDir\winget\minimal.json"
    } else {
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

    $selectedIds = Select-WithFzf $allIds "winget>" -AllowNew
    foreach ($id in $selectedIds) {
        $installed = winget list --id $id --accept-source-agreements 2>$null | Select-String $id
        if ($installed) {
            Write-Host "  [SKIP] $id already installed" -ForegroundColor DarkGray
        } else {
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

    $selectedIds = Select-WithFzf $allIds "winget-elevated>" -AllowNew
    foreach ($id in $selectedIds) {
        $installed = winget list --id $id --accept-source-agreements 2>$null | Select-String $id
        if ($installed) {
            Write-Host "  [SKIP] $id already installed" -ForegroundColor DarkGray
        } else {
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
    $file = "$PackagesDir\scoop\packages.json"
    if (-not (Test-Path $file)) { Write-Warning "No encontrado: $file"; return }

    $data = Get-Content $file | ConvertFrom-Json

    $data.buckets | ForEach-Object {
        if (-not (scoop bucket list | Select-Object -ExpandProperty Name | Where-Object { $_ -eq $_.Name })) {
            Write-Host "  Añadiendo bucket: $($_.Name)"
            scoop bucket add $_.Name $_.Source
        }
    }

    $allNames = @($data.apps | Select-Object -ExpandProperty Name | Sort-Object)
    $selectedNames = Select-WithFzf $allNames "scoop>" -AllowNew
    $installed = scoop list 2>$null | Select-Object -ExpandProperty Name

    foreach ($name in $selectedNames) {
        if ($installed -contains $name) {
            Write-Host "  [SKIP] $name already installed" -ForegroundColor DarkGray
        } else {
            $app = $data.apps | Where-Object { $_.Name -eq $name }
            Write-Host "  [....] $name" -ForegroundColor Cyan
            scoop install "$($app.Source)/$name"
        }
    }
    Write-Host "scoop restore OK" -ForegroundColor Green
}
Set-Alias -Name restore-scoop -Value Invoke-ScoopRestore

# -- npm -----------------------------------------------------------------------
function Invoke-NodeRestore {
    $file = "$PackagesDir\node\npm-packages.json"
    if (-not (Test-Path $file)) { Write-Warning "No encontrado: $file"; return }

    $data = Get-Content $file | ConvertFrom-Json
    if (-not $data.dependencies) { Write-Host "npm: no hay paquetes" -ForegroundColor Yellow; return }

    $allPkgs = @($data.dependencies.PSObject.Properties.Name | Sort-Object)
    $selectedPkgs = Select-WithFzf $allPkgs "npm>" -AllowNew
    $installed = npm list -g --depth=0 2>$null

    foreach ($pkg in $selectedPkgs) {
        if ($installed -match $pkg) {
            Write-Host "  [SKIP] $pkg already installed" -ForegroundColor DarkGray
        } else {
            Write-Host "  [....] $pkg" -ForegroundColor Cyan
            npm install -g $pkg
        }
    }
    Write-Host "npm restore OK" -ForegroundColor Green
}
Set-Alias -Name restore-node -Value Invoke-NodeRestore

# -- bun -----------------------------------------------------------------------
function Invoke-BunRestore {
    $file = "$PackagesDir\node\bun-packages.txt"
    if (-not (Test-Path $file)) { Write-Warning "No encontrado: $file"; return }

    $allPkgs = @(Get-Content $file | Where-Object { $_ } | Sort-Object)
    $selectedPkgs = Select-WithFzf $allPkgs "bun>" -AllowNew
    $installed = bun pm ls -g 2>$null

    foreach ($pkg in $selectedPkgs) {
        $pkgName = ($pkg -split '@')[0]
        if ($installed -match $pkgName) {
            Write-Host "  [SKIP] $pkg already installed" -ForegroundColor DarkGray
        } else {
            Write-Host "  [....] $pkg" -ForegroundColor Cyan
            bun add -g $pkg
        }
    }
    Write-Host "bun restore OK" -ForegroundColor Green
}
Set-Alias -Name restore-bun -Value Invoke-BunRestore

# -- uv ------------------------------------------------------------------------
function Invoke-UvRestore {
    $file = "$PackagesDir\uv-tools.txt"
    if (-not (Test-Path $file)) { Write-Warning "No encontrado: $file"; return }

    $allTools = @(Get-Content $file | Where-Object { $_ } | Sort-Object)
    $selectedTools = Select-WithFzf $allTools "uv>" -AllowNew
    $installed = uv tool list 2>$null

    foreach ($tool in $selectedTools) {
        if ($installed -match $tool) {
            Write-Host "  [SKIP] $tool already installed" -ForegroundColor DarkGray
        } else {
            Write-Host "  [....] $tool" -ForegroundColor Cyan
            uv tool install $tool
        }
    }
    Write-Host "uv restore OK" -ForegroundColor Green
}
Set-Alias -Name restore-uv -Value Invoke-UvRestore

# -- bin -----------------------------------------------------------------------
function Invoke-BinRestore {
    $file = "$PackagesDir\bin-packages.txt"
    if (-not (Test-Path $file)) { Write-Warning "No encontrado: $file"; return }

    $allPkgs = @(Get-Content $file | Where-Object { $_ } | Sort-Object)
    $selectedPkgs = Select-WithFzf $allPkgs "bin>" -AllowNew
    $installed = bin list 2>$null

    foreach ($pkg in $selectedPkgs) {
        $baseUrl = $pkg -replace '/releases/.*', ''
        if ($installed -match [regex]::Escape($baseUrl)) {
            Write-Host "  [SKIP] $pkg already installed" -ForegroundColor DarkGray
        } else {
            Write-Host "  [....] $pkg" -ForegroundColor Cyan
            bin install $pkg
        }
    }
    Write-Host "bin restore OK" -ForegroundColor Green
}
Set-Alias -Name restore-bin -Value Invoke-BinRestore
