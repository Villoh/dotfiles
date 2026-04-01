# migrate-to-scoop.ps1
# Interactively migrates packages between package managers.
# Auto-suggests target names from local bucket manifests; prompts for unknowns.
#
# Usage:
#   migrate                      # defaults: winget -> scoop
#   migrate -Source winget -Target scoop

function Invoke-Migration {
    param(
        [string]$Source = "winget",
        [string]$Target = "scoop"
    )

    switch ("$Source->$Target") {
        "winget->scoop" { Invoke-WingetToScoopMigration }
        default {
            Write-Warning "Migration '$Source -> $Target' is not supported."
            Write-Host "  Supported: winget -> scoop" -ForegroundColor Yellow
        }
    }
}

# -- winget -> scoop -----------------------------------------------------------

function Invoke-WingetToScoopMigration {
    $pkgDir      = "$(chezmoi source-path)/packages/windows".Replace('/', '\')
    $wingetFile  = "$pkgDir\winget\packages.json"
    $scoopFile   = "$pkgDir\scoop\packages.json"
    $startupFile = "$pkgDir\system\startup.json"

    $wingetData  = Get-Content $wingetFile  | ConvertFrom-Json
    $scoopData   = Get-Content $scoopFile   | ConvertFrom-Json
    $startupData = Get-Content $startupFile | ConvertFrom-Json

    $wingetIds   = @($wingetData.Sources | ForEach-Object { $_.Packages } |
                     Select-Object -ExpandProperty PackageIdentifier)
    $scoopNames  = @($scoopData.apps | Select-Object -ExpandProperty Name)

    # Load all available manifests from local scoop buckets (fast, no network)
    Write-Host "[migrate] Scanning scoop buckets..." -ForegroundColor Cyan
    $manifests = Get-ScoopManifests

    # Build candidate list with auto-suggestions
    $candidates = $wingetIds | ForEach-Object {
        $match = Find-ScoopMatch -WingetId $_ -Manifests $manifests
        [pscustomobject]@{
            WingetId    = $_
            ScoopName   = $match.Name
            Bucket      = $match.Bucket
            AutoMatched = $null -ne $match.Name
        }
    }

    # fzf display: show all winget packages with match status
    $fzfItems = $candidates | ForEach-Object {
        if ($_.AutoMatched) {
            "$($_.WingetId)  ->  $($_.Bucket)/$($_.ScoopName)"
        } else {
            "$($_.WingetId)  ->  ? [enter manually]"
        }
    }

    $selected = $fzfItems | fzf --multi --prompt="  migrate winget -> scoop> " `
        --header="TAB=toggle  CTRL-A=all  ENTER=confirm  ESC=cancel" `
        --layout=reverse --border --bind='ctrl-a:toggle-all' --bind='tab:toggle' `
        --color="hl:yellow,hl+:yellow"

    if (-not $selected) { Write-Host "Cancelled." -ForegroundColor Yellow; return }

    $selectedIds = @($selected | ForEach-Object { ($_ -split '\s+->\s+')[0].Trim() })
    $toMigrate   = $candidates | Where-Object { $selectedIds -contains $_.WingetId }

    # Resolve unknowns interactively
    foreach ($entry in $toMigrate | Where-Object { -not $_.AutoMatched }) {
        Write-Host ""
        Write-Host "  No scoop match found for: $($entry.WingetId)" -ForegroundColor Yellow
        $answer = Read-Host "  Enter scoop name (bucket/name or just name, empty to skip)"
        if (-not $answer) {
            $entry.ScoopName = $null
            continue
        }
        if ($answer -match '/') {
            $entry.Bucket    = ($answer -split '/')[0]
            $entry.ScoopName = ($answer -split '/')[1]
        } else {
            $entry.ScoopName = $answer
            # Try to find bucket from manifests
            $entry.Bucket = if ($manifests.ContainsKey($answer)) { $manifests[$answer] } else { "extras" }
        }
    }

    # Drop entries user skipped (empty name)
    $toMigrate = @($toMigrate | Where-Object { $_.ScoopName })

    if (-not $toMigrate) { Write-Host "Nothing to migrate." -ForegroundColor Yellow; return }

    # Ensure required buckets are added
    $bucketsNeeded = @($toMigrate | Select-Object -ExpandProperty Bucket -Unique | Where-Object { $_ })
    $scoopBuckets  = scoop bucket list | Select-Object -ExpandProperty Name 2>$null
    foreach ($b in $bucketsNeeded) {
        if ($scoopBuckets -notcontains $b) {
            Write-Host "  Adding scoop bucket: $b" -ForegroundColor Cyan
            scoop bucket add $b
        }
    }

    $ok = 0; $fail = 0

    foreach ($entry in $toMigrate) {
        $alreadyInScoop = $scoopNames -contains $entry.ScoopName
        $ref = if ($entry.Bucket) { "$($entry.Bucket)/$($entry.ScoopName)" } else { $entry.ScoopName }

        Write-Host ""
        Write-Host "  [$($entry.WingetId)  ->  $ref]" -ForegroundColor Cyan

        # 1. Install via scoop
        if ($alreadyInScoop) {
            Write-Host "    [SKIP] already in scoop/packages.json" -ForegroundColor DarkGray
        } else {
            $installed = scoop list 2>$null | Select-Object -ExpandProperty Name
            if ($installed -contains $entry.ScoopName) {
                Write-Host "    [SKIP] scoop: already installed" -ForegroundColor DarkGray
            } else {
                Write-Host "    [....] scoop install $ref" -ForegroundColor Gray
                scoop install $ref
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "    [FAIL] scoop install failed — skipping" -ForegroundColor Red
                    $fail++
                    continue
                }
            }
        }

        # 2. Uninstall from winget
        Write-Host "    [....] winget uninstall $($entry.WingetId)" -ForegroundColor Gray
        winget uninstall --id $entry.WingetId --accept-source-agreements 2>$null

        # 3. Auto-detect and patch startup.json path if needed
        $startupPatch = Get-StartupPatch -ScoopName $entry.ScoopName -StartupData $startupData
        if ($startupPatch) {
            $startupPatch.Entry.path = $startupPatch.NewPath
            Write-Host "    [OK]  startup.json: $($startupPatch.Entry.name)" -ForegroundColor Green
            Write-Host "          $($startupPatch.OldPath)"    -ForegroundColor DarkGray
            Write-Host "       -> $($startupPatch.NewPath)"    -ForegroundColor DarkGray
        }

        # 4. Remove from winget packages.json
        foreach ($src in $wingetData.Sources) {
            $src.Packages = @($src.Packages | Where-Object { $_.PackageIdentifier -ne $entry.WingetId })
        }
        Write-Host "    [OK]  removed from winget/packages.json" -ForegroundColor Green

        # 5. Add to scoop packages.json
        if (-not $alreadyInScoop) {
            $scoopData.apps += [pscustomobject]@{
                Info = ""; Version = ""; Updated = ""
                Name = $entry.ScoopName; Source = $entry.Bucket
            }
            Write-Host "    [OK]  added to scoop/packages.json" -ForegroundColor Green
        }

        $ok++
    }

    if ($ok -gt 0) {
        $wingetData  | ConvertTo-Json -Depth 10 | Set-Content $wingetFile  -Encoding UTF8
        $scoopData   | ConvertTo-Json -Depth 10 | Set-Content $scoopFile   -Encoding UTF8
        $startupData | ConvertTo-Json -Depth 10 | Set-Content $startupFile -Encoding UTF8
        Write-Host ""
        Write-Host "  Config files updated." -ForegroundColor Green
        Write-Host "  Run 'backup-scoop' to refresh versions in scoop/packages.json." -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host "  Done — $ok migrated  $fail failed" -ForegroundColor Cyan
}

# -- Helpers -------------------------------------------------------------------

function Get-ScoopManifests {
    # Returns hashtable: name (lowercase) -> bucket name
    # Reads local bucket manifest files — no network needed
    $result = @{}
    $bucketsPath = "$env:USERPROFILE\scoop\buckets"
    if (-not (Test-Path $bucketsPath)) { return $result }

    Get-ChildItem $bucketsPath -Directory | ForEach-Object {
        $bucket = $_.Name
        $manifestDir = Join-Path $_.FullName "bucket"
        if (Test-Path $manifestDir) {
            Get-ChildItem $manifestDir -Filter "*.json" -ErrorAction SilentlyContinue | ForEach-Object {
                $name = $_.BaseName.ToLower()
                if (-not $result.ContainsKey($name)) {
                    $result[$name] = $bucket
                }
            }
        }
    }
    return $result
}

function Find-ScoopMatch {
    param([string]$WingetId, [hashtable]$Manifests)

    # Generate candidate names from the winget ID in order of preference
    $after  = ($WingetId -split '\.', 2)[-1]          # everything after first dot
    $last   = ($WingetId -split '\.')[-1]              # last segment only

    $candidates = @(
        ($after.ToLower() -replace '[^a-z0-9-]', '-'),  # "Flow-Launcher.Flow-Launcher" -> "flow-launcher"
        ($last.ToLower()  -replace '[^a-z0-9-]', '-'),  # "Git.Git" -> "git"
        $last.ToLower()                                   # raw lowercase
    ) | Select-Object -Unique

    foreach ($c in $candidates) {
        if ($Manifests.ContainsKey($c)) {
            return @{ Name = $c; Bucket = $Manifests[$c] }
        }
    }
    return @{ Name = $null; Bucket = $null }
}

function Get-StartupPatch {
    param([string]$ScoopName, $StartupData)

    # Find the scoop install dir for this app
    $scoopAppDir = "$env:USERPROFILE\scoop\apps\$ScoopName\current"
    if (-not (Test-Path $scoopAppDir)) { return $null }

    $scoopExes = Get-ChildItem $scoopAppDir -Filter "*.exe" -ErrorAction SilentlyContinue

    foreach ($entry in $StartupData.registry) {
        $expanded = [System.Environment]::ExpandEnvironmentVariables($entry.path)
        # Skip if already pointing to scoop
        if ($expanded -like "*\scoop\*") { continue }

        $exeName = Split-Path $expanded -Leaf
        $match   = $scoopExes | Where-Object { $_.Name -ieq $exeName } | Select-Object -First 1
        if ($match) {
            # Build new path using %USERPROFILE% for portability
            $newPath = $match.FullName -replace [regex]::Escape($env:USERPROFILE), '%USERPROFILE%'
            return @{
                Entry   = $entry
                OldPath = $entry.path
                NewPath = $newPath
            }
        }
    }
    return $null
}

Set-Alias -Name migrate -Value Invoke-Migration
