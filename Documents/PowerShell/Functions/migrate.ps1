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
        return @(Get-Content $fallback |
            ForEach-Object { $_ -replace '\x1b\[[0-9;]*m', '' -replace '^[^\w@]+', '' } |
            Where-Object { $_ } |
            ForEach-Object { $_ -replace '@[0-9][^@]*$', '' })
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
    if ($LASTEXITCODE -ne 0) { Write-Host "    [FAIL] winget uninstall $Id" -ForegroundColor Red; return $false }
    Write-Host "    [OK]  winget uninstall $Id" -ForegroundColor Green; return $true
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
    if ($LASTEXITCODE -ne 0) { Write-Host "    [FAIL] scoop uninstall $Name" -ForegroundColor Red; return $false }
    Write-Host "    [OK]  scoop uninstall $Name" -ForegroundColor Green; return $true
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
    if ($LASTEXITCODE -ne 0) { Write-Host "    [FAIL] npm uninstall -g $Name" -ForegroundColor Red; return $false }
    Write-Host "    [OK]  npm uninstall -g $Name" -ForegroundColor Green; return $true
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
    if ($LASTEXITCODE -ne 0) { Write-Host "    [FAIL] bun remove -g $Name" -ForegroundColor Red; return $false }
    Write-Host "    [OK]  bun remove -g $Name" -ForegroundColor Green; return $true
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
    if ($LASTEXITCODE -ne 0) { Write-Host "    [FAIL] pnpm remove -g $Name" -ForegroundColor Red; return $false }
    Write-Host "    [OK]  pnpm remove -g $Name" -ForegroundColor Green; return $true
}

# -- Backup updaters -----------------------------------------------------------

function Update-WingetBackup  { Invoke-WingetBackup }
function Update-ScoopBackup   { Invoke-ScoopBackup }
function Update-NpmBackup     { Invoke-NodeBackup }
function Update-BunBackup     { Invoke-BunBackup }
function Update-PnpmBackup    { Invoke-PnpmBackup }

# -- Node migrations (npm / bun / pnpm, any direction) ------------------------

function Invoke-NodeMigration {
    param([string]$Source, [string]$Target)

    $getterMap = @{
        npm  = { Get-NpmGlobalPackages }
        bun  = { Get-BunGlobalPackages }
        pnpm = { Get-PnpmGlobalPackages }
    }
    $installMap = @{
        npm  = { param($n) Install-NpmPackage  $n }
        bun  = { param($n) Install-BunPackage  $n }
        pnpm = { param($n) Install-PnpmPackage $n }
    }
    $uninstallMap = @{
        npm  = { param($n) Uninstall-NpmPackage  $n }
        bun  = { param($n) Uninstall-BunPackage  $n }
        pnpm = { param($n) Uninstall-PnpmPackage $n }
    }
    $updateMap = @{
        npm  = { Update-NpmBackup }
        bun  = { Update-BunBackup }
        pnpm = { Update-PnpmBackup }
    }

    Write-Host "[migrate] Reading $Source global packages..." -ForegroundColor Cyan
    $packages = & $getterMap[$Source]

    if (-not $packages) {
        Write-Host "No packages found in $Source." -ForegroundColor Yellow
        return
    }

    $selected = Invoke-FzfPicker -Items $packages `
        -Prompt "  migrate $Source -> $Target> " `
        -Header "TAB=toggle  CTRL-A=all  ENTER=confirm  ESC=cancel"

    if (-not $selected) { Write-Host "Cancelled." -ForegroundColor Yellow; return }

    $ok = 0; $fail = 0

    foreach ($name in $selected) {
        Write-Host ""
        Write-Host "  [$name]" -ForegroundColor Cyan

        $installed = & $installMap[$Target] $name
        if (-not $installed) { $fail++; continue }

        $uninstalled = & $uninstallMap[$Source] $name
        if (-not $uninstalled) { $fail++; continue }
        $ok++
    }

    if ($ok -gt 0) {
        $sourceBackupOk = & $updateMap[$Source]
        $targetBackupOk = & $updateMap[$Target]
        Write-Host ""
        if ($sourceBackupOk -and $targetBackupOk) {
            Write-Host "  Backup files updated." -ForegroundColor Green
        } else {
            Write-Warning "Backup refresh failed for one or more package managers."
        }
    }

    Write-Host ""
    Write-Host "  Done — $ok migrated  $fail failed" -ForegroundColor Cyan
}

# -- winget -> scoop -----------------------------------------------------------

function Invoke-WingetToScoopMigration {
    $startupFile = "$script:PkgDir\system\startup.json"
    $startupData = if (Test-Path $startupFile) { Get-Content $startupFile | ConvertFrom-Json } else { $null }

    Write-Host "[migrate] Reading winget packages..." -ForegroundColor Cyan
    $wingetIds  = Get-WingetPackages
    $scoopNames = Get-ScoopPackages

    Write-Host "[migrate] Scanning scoop buckets..." -ForegroundColor Cyan
    $manifests = Get-ScoopManifests

    $candidates = $wingetIds | ForEach-Object {
        $match = Find-ScoopMatch -WingetId $_ -Manifests $manifests
        [pscustomobject]@{
            WingetId    = $_
            ScoopName   = $match.Name
            Bucket      = $match.Bucket
            AutoMatched = $null -ne $match.Name
        }
    }

    $fzfItems = $candidates | ForEach-Object {
        if ($_.AutoMatched) { "$($_.WingetId)  ->  $($_.Bucket)/$($_.ScoopName)" }
        else                { "$($_.WingetId)  ->  ? [enter manually]" }
    }

    $selected = Invoke-FzfPicker -Items $fzfItems `
        -Prompt "  migrate winget -> scoop> " `
        -Header "TAB=toggle  CTRL-A=all  ENTER=confirm  ESC=cancel"

    if (-not $selected) { Write-Host "Cancelled." -ForegroundColor Yellow; return }

    $selectedIds = @($selected | ForEach-Object { ($_ -split '\s+->\s+')[0].Trim() })
    $toMigrate   = $candidates | Where-Object { $selectedIds -contains $_.WingetId }

    foreach ($entry in $toMigrate | Where-Object { -not $_.AutoMatched }) {
        Write-Host ""
        Write-Host "  No scoop match found for: $($entry.WingetId)" -ForegroundColor Yellow
        Write-Host "  Enter scoop name (bucket/name or just name, empty to skip): " -NoNewline
        $answer = [Console]::ReadLine()
        if (-not $answer) { $entry.ScoopName = $null; continue }
        if ($answer -match '/') {
            $entry.Bucket    = ($answer -split '/')[0]
            $entry.ScoopName = ($answer -split '/')[1]
        } else {
            $entry.ScoopName = $answer
            $entry.Bucket    = if ($manifests.ContainsKey($answer)) { $manifests[$answer] } else { "extras" }
        }
    }

    $toMigrate = @($toMigrate | Where-Object { $_.ScoopName })
    if (-not $toMigrate) { Write-Host "Nothing to migrate." -ForegroundColor Yellow; return }

    $bucketsNeeded = @($toMigrate | Select-Object -ExpandProperty Bucket -Unique | Where-Object { $_ })
    $scoopBuckets  = scoop bucket list | Select-Object -ExpandProperty Name 2>$null
    foreach ($b in $bucketsNeeded) {
        if ($scoopBuckets -notcontains $b) {
            Write-Host "  Adding scoop bucket: $b" -ForegroundColor Cyan
            scoop bucket add $b
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Failed to add scoop bucket '$b'. Migration stopped."
                return
            }
        }
    }

    $ok = 0; $fail = 0

    foreach ($entry in $toMigrate) {
        $ref = if ($entry.Bucket) { "$($entry.Bucket)/$($entry.ScoopName)" } else { $entry.ScoopName }
        Write-Host ""
        Write-Host "  [$($entry.WingetId)  ->  $ref]" -ForegroundColor Cyan

        $alreadyInScoop = $scoopNames -contains $entry.ScoopName
        if (-not $alreadyInScoop) {
            $installed = scoop list 2>$null | Select-Object -ExpandProperty Name
            if ($installed -contains $entry.ScoopName) {
                Write-Host "    [SKIP] scoop: already installed" -ForegroundColor DarkGray
            } else {
                $ok_install = Install-ScoopPackage $ref
                if (-not $ok_install) { $fail++; continue }
            }
        } else {
            Write-Host "    [SKIP] already available in scoop" -ForegroundColor DarkGray
        }

        $uninstalled = Uninstall-WingetPackage $entry.WingetId
        if (-not $uninstalled) { $fail++; continue }

        if ($startupData) {
            $patch = Get-StartupPatch -ScoopName $entry.ScoopName -StartupData $startupData
            if ($patch) {
                $patch.Entry.path = $patch.NewPath
                Write-Host "    [OK]  startup.json: $($patch.Entry.name)" -ForegroundColor Green
            }
        }

        $ok++
    }

    if ($ok -gt 0) {
        if ($startupData) {
            $startupData | ConvertTo-Json -Depth 10 | Set-Content $startupFile -Encoding UTF8
        }
        $wingetBackupOk = Update-WingetBackup
        $scoopBackupOk = Update-ScoopBackup
        Write-Host ""
        if ($wingetBackupOk -and $scoopBackupOk) {
            Write-Host "  Backup files updated." -ForegroundColor Green
        } else {
            Write-Warning "Backup refresh failed for one or more package managers."
        }
    }

    Write-Host ""
    Write-Host "  Done — $ok migrated  $fail failed" -ForegroundColor Cyan
}

# -- scoop -> winget -----------------------------------------------------------

function Invoke-ScoopToWingetMigration {
    Write-Host "[migrate] Reading scoop packages..." -ForegroundColor Cyan
    $scoopNames = Get-ScoopPackages
    $null = Get-WingetPackages

    $selected = Invoke-FzfPicker -Items ($scoopNames | Sort-Object) `
        -Prompt "  migrate scoop -> winget> " `
        -Header "TAB=toggle  CTRL-A=all  ENTER=confirm  ESC=cancel"

    if (-not $selected) { Write-Host "Cancelled." -ForegroundColor Yellow; return }

    $migrations = @()
    foreach ($name in @($selected)) {
        Write-Host ""
        Write-Host "  Scoop package: $name" -ForegroundColor Cyan
        Write-Host "  Enter winget ID (empty to skip): " -NoNewline
        $wingetId = [Console]::ReadLine()
        if (-not $wingetId) { continue }
        $migrations += [pscustomobject]@{ ScoopName = $name; WingetId = $wingetId }
    }

    if (-not $migrations) { Write-Host "Nothing to migrate." -ForegroundColor Yellow; return }

    $ok = 0; $fail = 0

    foreach ($entry in $migrations) {
        Write-Host ""
        Write-Host "  [$($entry.ScoopName)  ->  $($entry.WingetId)]" -ForegroundColor Cyan

        $installed = winget list --id $entry.WingetId -e --accept-source-agreements 2>$null |
                     Select-String -SimpleMatch $entry.WingetId
        if ($installed) {
            Write-Host "    [SKIP] winget: already installed" -ForegroundColor DarkGray
        } else {
            $ok_install = Install-WingetPackage $entry.WingetId
            if (-not $ok_install) { $fail++; continue }
        }

        $uninstalled = Uninstall-ScoopPackage $entry.ScoopName
        if (-not $uninstalled) { $fail++; continue }
        $ok++
    }

    if ($ok -gt 0) {
        $scoopBackupOk = Update-ScoopBackup
        $wingetBackupOk = Update-WingetBackup
        Write-Host ""
        if ($scoopBackupOk -and $wingetBackupOk) {
            Write-Host "  Backup files updated." -ForegroundColor Green
        } else {
            Write-Warning "Backup refresh failed for one or more package managers."
        }
    }

    Write-Host ""
    Write-Host "  Done — $ok migrated  $fail failed" -ForegroundColor Cyan
}

# -- Helpers (scoop/winget) ----------------------------------------------------

function Get-ScoopManifests {
    $result = @{}
    $bucketsPath = "$env:USERPROFILE\scoop\buckets"
    if (-not (Test-Path $bucketsPath)) { return $result }
    Get-ChildItem $bucketsPath -Directory | ForEach-Object {
        $bucket = $_.Name
        $manifestDir = Join-Path $_.FullName "bucket"
        if (Test-Path $manifestDir) {
            Get-ChildItem $manifestDir -Filter "*.json" -ErrorAction SilentlyContinue | ForEach-Object {
                $name = $_.BaseName.ToLower()
                if (-not $result.ContainsKey($name)) { $result[$name] = $bucket }
            }
        }
    }
    return $result
}

function Find-ScoopMatch {
    param([string]$WingetId, [hashtable]$Manifests)
    $after = ($WingetId -split '\.', 2)[-1]
    $last  = ($WingetId -split '\.')[-1]
    $candidates = @(
        ($after.ToLower() -replace '[^a-z0-9-]', '-'),
        ($last.ToLower()  -replace '[^a-z0-9-]', '-'),
        $last.ToLower()
    ) | Select-Object -Unique
    foreach ($c in $candidates) {
        if ($Manifests.ContainsKey($c)) { return @{ Name = $c; Bucket = $Manifests[$c] } }
    }
    return @{ Name = $null; Bucket = $null }
}

function Get-StartupPatch {
    param([string]$ScoopName, $StartupData)
    $scoopAppDir = "$env:USERPROFILE\scoop\apps\$ScoopName\current"
    if (-not (Test-Path $scoopAppDir)) { return $null }
    $scoopExes = Get-ChildItem $scoopAppDir -Filter "*.exe" -ErrorAction SilentlyContinue
    foreach ($entry in $StartupData.registry) {
        $expanded = [System.Environment]::ExpandEnvironmentVariables($entry.path)
        if ($expanded -like "*\scoop\*") { continue }
        $exeName = Split-Path $expanded -Leaf
        $match   = $scoopExes | Where-Object { $_.Name -ieq $exeName } | Select-Object -First 1
        if ($match) {
            # Patch only the first matching startup entry for this Scoop app.
            $newPath = $match.FullName -replace [regex]::Escape($env:USERPROFILE), '%USERPROFILE%'
            return @{ Entry = $entry; OldPath = $entry.path; NewPath = $newPath }
        }
    }
    return $null
}

Set-Alias -Name migrate -Value Invoke-Migration
