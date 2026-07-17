# restore.ps1
$PackagesDir = "$env:USERPROFILE\.local\share\chezmoi\packages\windows"

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
    $pkgDir = $PackagesDir

    $candidates = [System.Collections.Generic.List[string]]::new()
    if (Test-Path "$pkgDir\winget\packages.json" -or Test-Path "$pkgDir\winget\minimal.json") {
        $candidates.Add("winget")
    }
    if (Test-Path "$pkgDir\winget\elevated.json") { $candidates.Add("winget-elevated") }
    if (Test-Path "$pkgDir\scoop\packages.json") { $candidates.Add("scoop") }
    if (Test-Path "$pkgDir\node\npm-packages.json") { $candidates.Add("npm") }
    if (Test-Path "$pkgDir\node\bun-packages.txt") { $candidates.Add("bun") }
    if (Test-Path "$pkgDir\node\pnpm-packages.txt") { $candidates.Add("pnpm") }
    if (Test-Path "$pkgDir\uv-tools.txt") { $candidates.Add("uv") }
    if (Test-Path "$pkgDir\bin-packages.txt") { $candidates.Add("bin") }
    if (Test-Path "$pkgDir\cargo\cargo.txt" -or Test-Path "$pkgDir\cargo\cargo-minimal.txt") { $candidates.Add("cargo") }

    $selectedManagers = Select-WithFzf $candidates.ToArray() "Package managers>" `
        "TAB=toggle  CTRL-A=all  ENTER=confirm  ESC=skip all"

    if (-not $selectedManagers -or $selectedManagers.Count -eq 0) {
        Write-Host "No managers selected." -ForegroundColor Yellow
        return
    }

    if ($selectedManagers -contains "winget") { Invoke-WingetRestore }
    if ($selectedManagers -contains "winget-elevated") { Invoke-WingetElevatedRestore }
    if ($selectedManagers -contains "scoop") { Invoke-ScoopRestore }
    if ($selectedManagers -contains "npm") { Invoke-NodeRestore }
    if ($selectedManagers -contains "bun") { Invoke-BunRestore }
    if ($selectedManagers -contains "pnpm") { Invoke-PnpmRestore }
    if ($selectedManagers -contains "uv") { Invoke-UvRestore }
    if ($selectedManagers -contains "bin") { Invoke-BinRestore }
    if ($selectedManagers -contains "cargo") { Invoke-CargoRestore }

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

# -- npm -----------------------------------------------------------------------
function Invoke-NodeRestore {
    $file = "$PackagesDir\node\npm-packages.json"
    if (-not (Test-Path $file)) { Write-Warning "No encontrado: $file"; return }

    $data = Get-Content $file | ConvertFrom-Json
    if (-not $data.dependencies) { Write-Host "npm: no hay paquetes" -ForegroundColor Yellow; return }

    $allPkgs = @($data.dependencies.PSObject.Properties.Name | Sort-Object)
    $selectedPkgs = Select-WithFzf $allPkgs "npm>"
    $installed = npm list -g --depth=0 2>$null

    foreach ($pkg in $selectedPkgs) {
        if ($installed -match $pkg) {
            Write-Host "  [SKIP] $pkg already installed" -ForegroundColor DarkGray
        }
        else {
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
    $selectedPkgs = Select-WithFzf $allPkgs "bun>"
    $installed = bun pm ls -g 2>$null

    foreach ($pkg in $selectedPkgs) {
        $pkgName = ($pkg -split '@')[0]
        if ($installed -match $pkgName) {
            Write-Host "  [SKIP] $pkg already installed" -ForegroundColor DarkGray
        }
        else {
            Write-Host "  [....] $pkg" -ForegroundColor Cyan
            bun add -g $pkg
        }
    }
    Write-Host "bun restore OK" -ForegroundColor Green
}
Set-Alias -Name restore-bun -Value Invoke-BunRestore

# -- pnpm ----------------------------------------------------------------------
function Invoke-PnpmRestore {
    $file = "$PackagesDir\node\pnpm-packages.txt"
    if (-not (Test-Path $file)) { Write-Warning "No encontrado: $file"; return }

    $allPkgs = @(Get-Content $file | Where-Object { $_ } | Sort-Object)
    $selectedPkgs = Select-WithFzf $allPkgs "pnpm>"

    $installedNames = @()
    try {
        $installedJson = pnpm list -g --json 2>$null | ConvertFrom-Json
        if ($installedJson -and $installedJson[0].dependencies) {
            $installedNames = $installedJson[0].dependencies.PSObject.Properties.Name
        }
    }
    catch {}

    foreach ($pkg in $selectedPkgs) {
        if ($installedNames -contains $pkg) {
            Write-Host "  [SKIP] $pkg already installed" -ForegroundColor DarkGray
        }
        else {
            Write-Host "  [....] $pkg" -ForegroundColor Cyan
            pnpm add -g $pkg
        }
    }
    Write-Host "pnpm restore OK" -ForegroundColor Green
}
Set-Alias -Name restore-pnpm -Value Invoke-PnpmRestore

# -- uv ------------------------------------------------------------------------
function Invoke-UvRestore {
    $file = "$PackagesDir\uv-tools.txt"
    if (-not (Test-Path $file)) { Write-Warning "No encontrado: $file"; return }

    $allTools = @(Get-Content $file | Where-Object { $_ } | Sort-Object)
    $selectedTools = Select-WithFzf $allTools "uv>"
    $installed = uv tool list 2>$null

    foreach ($tool in $selectedTools) {
        if ($installed -match $tool) {
            Write-Host "  [SKIP] $tool already installed" -ForegroundColor DarkGray
        }
        else {
            Write-Host "  [....] $tool" -ForegroundColor Cyan
            uv tool install $tool
        }
    }
    Write-Host "uv restore OK" -ForegroundColor Green
}
Set-Alias -Name restore-uv -Value Invoke-UvRestore

# -- cargo (crates.io + git) ---------------------------------------------------
function Invoke-CargoRestore {
    $pkgDir = $PackagesDir

    if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
        Write-Host "  [WARN] cargo not found - install rustup first" -ForegroundColor Yellow; return
    }

    $profiles = @()
    if (Test-Path "$pkgDir\cargo\cargo-minimal.txt") { $profiles += "minimal  |  curated subset" }
    if (Test-Path "$pkgDir\cargo\cargo.txt") { $profiles += "full     |  all packages" }

    if ($profiles.Count -eq 0) { Write-Warning "No cargo package files found"; return }

    $profileChoice = Select-OneFzf $profiles "cargo profile>"
    $profileKey = if ($profileChoice) { ($profileChoice -split '\s*\|')[0].Trim() } else { "minimal" }
    $file = if ($profileKey -eq "minimal") {
        "$pkgDir\cargo\cargo-minimal.txt"
    }
    else {
        "$pkgDir\cargo\cargo.txt"
    }

    if (-not (Test-Path $file)) { Write-Warning "No encontrado: $file"; return }
    Write-Host "  Profile: $(Split-Path $file -Leaf)" -ForegroundColor Cyan

    $allEntries = @(Get-Content $file | Where-Object { $_.Trim() -ne "" -and -not $_.TrimStart().StartsWith('#') } | Sort-Object)
    $selectedEntries = Select-WithFzf $allEntries "cargo>"
    $installed = cargo install --list 2>$null

    foreach ($entry in $selectedEntries) {
        if ($entry -match '^https://') {
            $baseUrl = ($entry -split '\s+')[0] -replace '\.git$', ''
            if ($installed -match [regex]::Escape($baseUrl)) {
                Write-Host "  [SKIP] $baseUrl already installed" -ForegroundColor DarkGray
            }
            else {
                Write-Host "  [....] $entry" -ForegroundColor Cyan
                try {
                    Invoke-Expression "cargo install --git $entry"
                    if ($LASTEXITCODE -ne 0) { throw "exit code $LASTEXITCODE" }
                    Write-Host "  [OK]   $baseUrl" -ForegroundColor Green
                }
                catch {
                    Write-Host "  [FAIL] $entry - $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
        else {
            if ($installed -match "^$([regex]::Escape($entry))\s") {
                Write-Host "  [SKIP] $entry already installed" -ForegroundColor DarkGray
            }
            else {
                Write-Host "  [....] $entry" -ForegroundColor Cyan
                cargo install $entry
            }
        }
    }
    Write-Host "cargo restore OK" -ForegroundColor Green
}
Set-Alias -Name restore-cargo     -Value Invoke-CargoRestore

# -- bin -----------------------------------------------------------------------
function Invoke-BinRestore {
    $file = "$PackagesDir\bin-packages.txt"
    if (-not (Test-Path $file)) { Write-Warning "No encontrado: $file"; return }

    $allPkgs = @(Get-Content $file | Where-Object { $_ } | Sort-Object)
    $selectedPkgs = Select-WithFzf $allPkgs "bin>"
    $installed = bin list 2>$null

    foreach ($pkg in $selectedPkgs) {
        $baseUrl = $pkg -replace '/releases/.*', ''
        if ($installed -match [regex]::Escape($baseUrl)) {
            Write-Host "  [SKIP] $pkg already installed" -ForegroundColor DarkGray
        }
        else {
            Write-Host "  [....] $pkg" -ForegroundColor Cyan
            bin install $pkg
        }
    }
    Write-Host "bin restore OK" -ForegroundColor Green
}
Set-Alias -Name restore-bin -Value Invoke-BinRestore

# -- windhawk --------------------------------------------------------------------
function Invoke-WindhawkRestore {
    $sourceDir = chezmoi source-path
    $regFile = "$sourceDir\packages\windows\system\windhawk\settings.reg"
    $pfDir = "$sourceDir\program_files\windhawk"
    $tmpScript = "$env:TEMP\windhawk-restore.ps1"
    $logFile = "$env:TEMP\windhawk-restore.log"

    if (-not (Test-Path $regFile) -and -not (Test-Path $pfDir)) {
        Write-Warning "No hay backup de windhawk en $pfDir"
        return
    }

    @"
`$regFile = "$regFile"
`$pfDir    = "$pfDir"
`$logFile  = "$logFile"
`$lines    = @()
if (Test-Path `$regFile) {
    reg import `$regFile | Out-Null
    `$lines += "reg:OK"
}
if (Test-Path "`$pfDir\32") {
    New-Item -ItemType Directory -Force -Path "C:\ProgramData\Windhawk\Engine\Mods\32" | Out-Null
    `$dlls32 = Copy-Item "`$pfDir\32\*.dll" "C:\ProgramData\Windhawk\Engine\Mods\32\" -Force -PassThru -ErrorAction SilentlyContinue
    `$lines += "dlls32:OK (`$(`$dlls32.Count))"
}
if (Test-Path "`$pfDir\64") {
    New-Item -ItemType Directory -Force -Path "C:\ProgramData\Windhawk\Engine\Mods\64" | Out-Null
    `$dlls64 = Copy-Item "`$pfDir\64\*.dll" "C:\ProgramData\Windhawk\Engine\Mods\64\" -Force -PassThru -ErrorAction SilentlyContinue
    `$lines += "dlls64:OK (`$(`$dlls64.Count))"
}
if (Test-Path "`$pfDir\userprofile.json") {
    Copy-Item "`$pfDir\userprofile.json" "C:\ProgramData\Windhawk\userprofile.json" -Force
    `$lines += "userprofile:OK"
}
if (Test-Path "`$pfDir\ModsSource") {
    New-Item -ItemType Directory -Force -Path "C:\ProgramData\Windhawk\ModsSource" | Out-Null
    `$src = Copy-Item "`$pfDir\ModsSource\*.wh.cpp" "C:\ProgramData\Windhawk\ModsSource\" -Force -PassThru -ErrorAction SilentlyContinue
    `$lines += "modssource:OK (`$(`$src.Count))"
}
`$lines | Set-Content `$logFile
"@ | Set-Content $tmpScript

    Start-Process powershell.exe -Verb RunAs -WindowStyle Hidden -ArgumentList "-NoProfile", "-File", $tmpScript -Wait
    Remove-Item $tmpScript -ErrorAction SilentlyContinue

    if (Test-Path $logFile) {
        Get-Content $logFile | ForEach-Object { Write-Host "  [OK] $_" -ForegroundColor Green }
        Remove-Item $logFile
    }
    else {
        Write-Warning "windhawk restore: no output from elevated script (UAC cancelled or failed)"
        return
    }
    Write-Host "windhawk restore OK" -ForegroundColor Green
}
Set-Alias -Name restore-windhawk -Value Invoke-WindhawkRestore

