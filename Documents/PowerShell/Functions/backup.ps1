# backup.ps1
$SourceDir = chezmoi source-path
$PackagesDir = Join-Path $SourceDir "packages\windows"
$HerdrPluginsFile = Join-Path $SourceDir "packages\windows\herdr-plugins.json"

function Save-ExistingBackup {
    param([string]$Path)
    New-Item -ItemType Directory -Force -Path (Split-Path $Path) -ErrorAction Stop | Out-Null
    if (Test-Path $Path) {
        Copy-Item $Path "$Path.bak" -Force
    }
}

function Invoke-AllBackup {
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [ValidateSet('winget', 'scoop', 'herdr')]
        [string[]]$Manager = @('winget', 'scoop', 'herdr')
    )
    New-Item -ItemType Directory -Force -Path $PackagesDir | Out-Null
    $results = @(
        if ($Manager -contains 'winget') { Invoke-WingetBackup }
        if ($Manager -contains 'scoop') { Invoke-ScoopBackup }
        if ($Manager -contains 'herdr') { Invoke-HerdrBackup }
    )
    if ($results -contains $false) {
        Write-Warning "Backup failed for one or more sources."
        return $false
    }
    Write-Host "Backup completado en $PackagesDir" -ForegroundColor Green
    return $true
}
Set-Alias -Name backup         -Value Invoke-AllBackup
Set-Alias -Name backup-pkgs    -Value Invoke-AllBackup

function Invoke-WingetBackup {
    $file        = "$PackagesDir\winget\packages.json"
    $excludeFile = "$PackagesDir\winget\exclude.txt"
    $tmp         = "$env:TEMP\winget-export-raw.json"

    try {
        Save-ExistingBackup $file
        winget export -o $tmp --source winget --accept-source-agreements
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path $tmp)) { throw "winget export failed" }

        $data = Get-Content $tmp | ConvertFrom-Json

        if (Test-Path $excludeFile) {
            $excluded = Get-Content $excludeFile | Where-Object { $_.Trim() -and -not $_.StartsWith('#') }
            foreach ($source in $data.Sources) {
                $source.Packages = $source.Packages | Where-Object {
                    $_.PackageIdentifier -notin $excluded
                }
            }
            Write-Host "  (excluded $($excluded.Count) packages from winget/exclude.txt)" -ForegroundColor DarkGray
        }

        $data | ConvertTo-Json -Depth 10 | Set-Content $file -Encoding UTF8
        Remove-Item $tmp -ErrorAction SilentlyContinue

        $count = ($data.Sources | ForEach-Object { $_.Packages.Count } | Measure-Object -Sum).Sum
        Write-Host "winget backup OK ($count packages)" -ForegroundColor Green
        return $true
    } catch {
        Remove-Item $tmp -ErrorAction SilentlyContinue
        Write-Warning "winget backup failed: $_"
        return $false
    }
}
Set-Alias -Name backup-winget  -Value Invoke-WingetBackup

function Invoke-ScoopBackup {
    $file = "$PackagesDir\scoop\packages.json"
    Save-ExistingBackup $file
    scoop export > $file
    if ($LASTEXITCODE -ne 0) { Write-Warning "scoop backup failed"; return $false }
    Write-Host "scoop backup OK" -ForegroundColor Green
    return $true
}
Set-Alias -Name backup-scoop   -Value Invoke-ScoopBackup

function Invoke-HerdrBackup {
    if (-not (Get-Command herdr -ErrorAction SilentlyContinue)) {
        Write-Host "Herdr not installed; skipping" -ForegroundColor Yellow
        return $true
    }

    try {
        $result = herdr plugin list --json | ConvertFrom-Json
        if ($LASTEXITCODE -ne 0 -or $result.result.plugins -isnot [array]) { throw "invalid Herdr plugin list" }

        $inventory = @(foreach ($plugin in $result.result.plugins) {
            if ($plugin.plugin_id -isnot [string] -or $plugin.plugin_id -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$' -or $plugin.enabled -isnot [bool]) {
                throw "invalid plugin entry"
            }
            switch ($plugin.source.kind) {
                'github' {
                    $owner = $plugin.source.owner
                    $repo = $plugin.source.repo
                    $subdir = $plugin.source.subdir
                    if ($owner -notmatch '^[A-Za-z0-9_.-]+$' -or $repo -notmatch '^[A-Za-z0-9_.-]+$' -or $subdir -match '(^|/)\.\.?(/|$)') {
                        throw "invalid GitHub source for $($plugin.plugin_id)"
                    }
                    $source = "$owner/$repo"
                    if ($subdir) { $source += "/$subdir" }
                    $kind = 'github'
                }
                'local' {
                    $path = [System.IO.Path]::GetFullPath($plugin.plugin_root)
                    $homePrefix = [System.IO.Path]::GetFullPath($HOME).TrimEnd('\') + '\'
                    if (-not $path.StartsWith($homePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                        throw "local plugin outside HOME: $($plugin.plugin_id)"
                    }
                    $source = $path.Substring($homePrefix.Length).Replace('\', '/')
                    $kind = 'local'
                }
                default { throw "unknown source kind for $($plugin.plugin_id)" }
            }
            [pscustomobject]@{ id = $plugin.plugin_id; enabled = $plugin.enabled; kind = $kind; source = $source; ref = $null }
        })

        $json = ConvertTo-Json -InputObject ([object[]]$inventory) -Depth 5
        New-Item -ItemType Directory -Force -Path (Split-Path $HerdrPluginsFile) | Out-Null
        Save-ExistingBackup $HerdrPluginsFile
        $json | Set-Content $HerdrPluginsFile -Encoding UTF8
        Write-Host "Herdr backup OK ($($inventory.Count) plugins; refs omitted)" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Warning "Herdr backup failed: $_"
        return $false
    }
}
Set-Alias -Name backup-herdr -Value Invoke-HerdrBackup
