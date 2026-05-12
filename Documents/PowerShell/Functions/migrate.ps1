# migrate.ps1
# Interactively migrates packages between package managers.
# Runtime queries are the source of truth; backup JSON/txt is fallback.
#
# Usage:
#   migrate                        # defaults: winget -> scoop
#   migrate -Source winget -Target scoop
#   migrate -Source npm    -Target bun
#   migrate -Source bun    -Target pnpm
#   (etc.)

$script:PkgDir = "$(chezmoi source-path)/packages/windows".Replace('/', '\')

function Invoke-Migration {
    param(
        [string]$Source = "winget",
        [string]$Target = "scoop"
    )

    switch ("$Source->$Target") {
        "winget->scoop" { Invoke-WingetToScoopMigration }
        "scoop->winget" { Invoke-ScoopToWingetMigration }
        "npm->bun"      { Invoke-NodeMigration -Source npm  -Target bun  }
        "npm->pnpm"     { Invoke-NodeMigration -Source npm  -Target pnpm }
        "bun->npm"      { Invoke-NodeMigration -Source bun  -Target npm  }
        "bun->pnpm"     { Invoke-NodeMigration -Source bun  -Target pnpm }
        "pnpm->npm"     { Invoke-NodeMigration -Source pnpm -Target npm  }
        "pnpm->bun"     { Invoke-NodeMigration -Source pnpm -Target bun  }
        default {
            Write-Warning "Migration '$Source -> $Target' is not supported."
            Write-Host "  Supported pairs:" -ForegroundColor Yellow
            Write-Host "    winget <-> scoop" -ForegroundColor Yellow
            Write-Host "    npm / bun / pnpm (any direction)" -ForegroundColor Yellow
        }
    }
}

function Invoke-FzfPicker {
    param(
        [string[]]$Items,
        [string]$Prompt = "  migrate> ",
        [string]$Header = "TAB=toggle  CTRL-A=all  ENTER=confirm  ESC=cancel"
    )
    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
        Write-Error "fzf not found. Install with: scoop install fzf"
        return @()
    }
    $selected = $Items | fzf --multi --prompt=$Prompt `
        --header=$Header `
        --layout=reverse --border `
        --bind='ctrl-a:toggle-all' --bind='tab:toggle' `
        --color="hl:yellow,hl+:yellow"
    if (-not $selected) { return @() }
    return @($selected)
}

# -- Runtime getters -----------------------------------------------------------

function Get-WingetPackages {
    $fallback = "$script:PkgDir\winget\packages.json"
    try {
        $tmp = "$env:TEMP\winget-migrate-export.json"
        winget export -o $tmp --source winget --accept-source-agreements 2>$null
        if ($LASTEXITCODE -ne 0) { throw "winget export failed" }
        $data = Get-Content $tmp | ConvertFrom-Json
        Remove-Item $tmp -ErrorAction SilentlyContinue
        return @($data.Sources | ForEach-Object { $_.Packages } |
                 Select-Object -ExpandProperty PackageIdentifier)
    } catch {
        Write-Warning "  [warn] winget runtime query failed, using backup JSON"
        if (-not (Test-Path $fallback)) {
            Write-Warning "  [warn] fallback $fallback not found — no packages loaded"
            return @()
        }
        $data = Get-Content $fallback | ConvertFrom-Json
        return @($data.Sources | ForEach-Object { $_.Packages } |
                 Select-Object -ExpandProperty PackageIdentifier)
    }
}

function Get-ScoopPackages {
    $fallback = "$script:PkgDir\scoop\packages.json"
    try {
        $list = scoop list 2>$null
        if ($LASTEXITCODE -ne 0) { throw "scoop list failed" }
        return @($list | Select-Object -ExpandProperty Name)
    } catch {
        Write-Warning "  [warn] scoop runtime query failed, using backup JSON"
        if (-not (Test-Path $fallback)) {
            Write-Warning "  [warn] fallback $fallback not found — no packages loaded"
            return @()
        }
        $data = Get-Content $fallback | ConvertFrom-Json
        return @($data.apps | Select-Object -ExpandProperty Name)
    }
}

function Get-NpmGlobalPackages {
    $fallback = "$script:PkgDir\node\npm-packages.json"
    try {
        $json = npm list -g --depth=0 --json 2>$null | ConvertFrom-Json
        if (-not $json -or -not $json.dependencies) { return @() }
        return @($json.dependencies.PSObject.Properties.Name)
    } catch {
        Write-Warning "  [warn] npm runtime query failed, using backup JSON"
        if (-not (Test-Path $fallback)) {
            Write-Warning "  [warn] fallback $fallback not found — no packages loaded"
            return @()
        }
        $json = Get-Content $fallback | ConvertFrom-Json
        return @($json.dependencies.PSObject.Properties.Name)
    }
}

function Get-BunGlobalPackages {
    $fallback = "$script:PkgDir\node\bun-packages.txt"
    try {
        $raw = bun pm ls -g 2>$null
        if ($LASTEXITCODE -ne 0) { throw "bun pm ls -g failed" }
        $lines = $raw | Select-Object -Skip 1
        return @($lines |
            ForEach-Object { $_ -replace '\x1b\[[0-9;]*m', '' -replace '^[^\w@]+', '' } |
            Where-Object { $_ } |
            ForEach-Object { $_ -replace '@[0-9][^@]*$', '' })
    } catch {
        Write-Warning "  [warn] bun runtime query failed, using backup txt"
        if (-not (Test-Path $fallback)) {
            Write-Warning "  [warn] fallback $fallback not found — no packages loaded"
            return @()
        }
        return @(Get-Content $fallback | Where-Object { $_ })
    }
}

function Get-PnpmGlobalPackages {
    $fallback = "$script:PkgDir\node\pnpm-packages.txt"
    try {
        $json = pnpm list -g --json 2>$null | ConvertFrom-Json
        $deps = $json[0].dependencies
        if (-not $deps) { return @() }
        return @($deps.PSObject.Properties.Name)
    } catch {
        Write-Warning "  [warn] pnpm runtime query failed, using backup txt"
        if (-not (Test-Path $fallback)) {
            Write-Warning "  [warn] fallback $fallback not found — no packages loaded"
            return @()
        }
        return @(Get-Content $fallback | Where-Object { $_ })
    }
}

# -- Install / Uninstall -------------------------------------------------------

function Install-WingetPackage([string]$Id) {
    Write-Host "    [....] winget install $Id" -ForegroundColor Gray
    winget install --id $Id --accept-package-agreements --accept-source-agreements --silent -e
    if ($LASTEXITCODE -ne 0) { Write-Host "    [FAIL] winget install $Id" -ForegroundColor Red; return $false }
    Write-Host "    [OK]  winget install $Id" -ForegroundColor Green; return $true
}

function Uninstall-WingetPackage([string]$Id) {
    Write-Host "    [....] winget uninstall $Id" -ForegroundColor Gray
    winget uninstall --id $Id --accept-source-agreements --silent 2>$null
    Write-Host "    [OK]  winget uninstall $Id" -ForegroundColor Green
}

function Install-ScoopPackage([string]$Ref) {
    Write-Host "    [....] scoop install $Ref" -ForegroundColor Gray
    scoop install $Ref
    if ($LASTEXITCODE -ne 0) { Write-Host "    [FAIL] scoop install $Ref" -ForegroundColor Red; return $false }
    Write-Host "    [OK]  scoop install $Ref" -ForegroundColor Green; return $true
}

function Uninstall-ScoopPackage([string]$Name) {
    Write-Host "    [....] scoop uninstall $Name" -ForegroundColor Gray
    scoop uninstall $Name 2>$null
    Write-Host "    [OK]  scoop uninstall $Name" -ForegroundColor Green
}

function Install-NpmPackage([string]$Name) {
    Write-Host "    [....] npm install -g $Name" -ForegroundColor Gray
    npm install -g $Name
    if ($LASTEXITCODE -ne 0) { Write-Host "    [FAIL] npm install -g $Name" -ForegroundColor Red; return $false }
    Write-Host "    [OK]  npm install -g $Name" -ForegroundColor Green; return $true
}

function Uninstall-NpmPackage([string]$Name) {
    Write-Host "    [....] npm uninstall -g $Name" -ForegroundColor Gray
    npm uninstall -g $Name
    Write-Host "    [OK]  npm uninstall -g $Name" -ForegroundColor Green
}

function Install-BunPackage([string]$Name) {
    Write-Host "    [....] bun add -g $Name" -ForegroundColor Gray
    bun add -g $Name
    if ($LASTEXITCODE -ne 0) { Write-Host "    [FAIL] bun add -g $Name" -ForegroundColor Red; return $false }
    Write-Host "    [OK]  bun add -g $Name" -ForegroundColor Green; return $true
}

function Uninstall-BunPackage([string]$Name) {
    Write-Host "    [....] bun remove -g $Name" -ForegroundColor Gray
    bun remove -g $Name
    Write-Host "    [OK]  bun remove -g $Name" -ForegroundColor Green
}

function Install-PnpmPackage([string]$Name) {
    Write-Host "    [....] pnpm add -g $Name" -ForegroundColor Gray
    pnpm add -g $Name
    if ($LASTEXITCODE -ne 0) { Write-Host "    [FAIL] pnpm add -g $Name" -ForegroundColor Red; return $false }
    Write-Host "    [OK]  pnpm add -g $Name" -ForegroundColor Green; return $true
}

function Uninstall-PnpmPackage([string]$Name) {
    Write-Host "    [....] pnpm remove -g $Name" -ForegroundColor Gray
    pnpm remove -g $Name
    Write-Host "    [OK]  pnpm remove -g $Name" -ForegroundColor Green
}

# -- Backup updaters -----------------------------------------------------------

function Update-WingetBackup  { Invoke-WingetBackup }
function Update-ScoopBackup   { Invoke-ScoopBackup }
function Update-NpmBackup     { Invoke-NodeBackup }
function Update-BunBackup     { Invoke-BunBackup }
function Update-PnpmBackup    { Invoke-PnpmBackup }

Set-Alias -Name migrate -Value Invoke-Migration
