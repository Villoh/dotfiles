# upgrade.ps1

function Invoke-AllUpgrade {
    Invoke-WingetUpgrade
    Invoke-ScoopUpgrade
    Invoke-NodeUpgrade
    Invoke-UvUpgrade
}
Set-Alias -Name upgrade-all       -Value Invoke-AllUpgrade
Set-Alias -Name update-all        -Value Invoke-AllUpgrade

function Invoke-WingetUpgrade {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { Write-Warning "winget not found."; return }
    winget upgrade --all --accept-package-agreements --accept-source-agreements --silent
}
Set-Alias -Name update-winget  -Value Invoke-WingetUpgrade
Set-Alias -Name upgrade-winget -Value Invoke-WingetUpgrade

function Invoke-ScoopUpgrade {
    if (Get-Command scoop -ErrorAction SilentlyContinue) { scoop update --all }
    else { Write-Warning "scoop not found." }
}
Set-Alias -Name update-scoop   -Value Invoke-ScoopUpgrade
Set-Alias -Name upgrade-scoop  -Value Invoke-ScoopUpgrade

function Invoke-NpmUpgrade {
    if (Get-Command npm -ErrorAction SilentlyContinue) { npm update -g }
    else { Write-Warning "npm not found." }
}
Set-Alias -Name update-npm     -Value Invoke-NpmUpgrade
Set-Alias -Name upgrade-npm    -Value Invoke-NpmUpgrade

function Invoke-BunUpgrade {
    if (-not (Get-Command bun -ErrorAction SilentlyContinue)) { Write-Warning "bun not found."; return }

    $outdated = @(bun outdated -g 2>$null | ForEach-Object {
        $line = ($_ -replace '\x1b\[[0-9;]*m', '').Trim()
        if (-not $line -or $line -match '^bun outdated ' -or $line -match '^\|[- ]+\|$' -or $line -match '^\|\s*Package\s*\|') {
            return
        }

        $columns = @($line -split '\|' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        if ($columns.Count -ge 4 -and -not (($columns | Where-Object { $_ -notmatch '^-+$' }).Count -eq 0)) {
            $pkgName = $columns[0]
            $current = $columns[1]
            $update = $columns[2]

            if ($current -ne $update) {
                [PSCustomObject]@{
                    Name = $pkgName
                    Version = $update
                }
            }
        }
    })

    if ($outdated.Count -eq 0) {
        Write-Host "bun: all global packages are up to date." -ForegroundColor Green
    } else {
        foreach ($pkg in $outdated) {
            bun add -g "$($pkg.Name)@$($pkg.Version)"
        }
    }
}
Set-Alias -Name update-bun     -Value Invoke-BunUpgrade
Set-Alias -Name upgrade-bun    -Value Invoke-BunUpgrade

function Invoke-PnpmUpgrade {
    if (-not (Get-Command pnpm -ErrorAction SilentlyContinue)) { Write-Warning "pnpm not found."; return }

    $outdated = pnpm outdated -g --format json 2>$null | ConvertFrom-Json
    if (-not $outdated) {
        Write-Host "pnpm: all global packages are up to date." -ForegroundColor Green
        return
    }

    foreach ($pkg in $outdated.PSObject.Properties.Name) {
        pnpm add -g "${pkg}@latest"
    }
}
Set-Alias -Name update-pnpm    -Value Invoke-PnpmUpgrade
Set-Alias -Name upgrade-pnpm   -Value Invoke-PnpmUpgrade

function Invoke-NodeUpgrade {
    Invoke-NpmUpgrade
    Invoke-BunUpgrade
    Invoke-PnpmUpgrade
}
Set-Alias -Name update-node    -Value Invoke-NodeUpgrade
Set-Alias -Name upgrade-node   -Value Invoke-NodeUpgrade

function Invoke-UvUpgrade {
    if (Get-Command uv -ErrorAction SilentlyContinue) { uv tool upgrade --all }
    else { Write-Warning "uv not found." }
}
Set-Alias -Name update-uv      -Value Invoke-UvUpgrade
Set-Alias -Name upgrade-uv     -Value Invoke-UvUpgrade

function Invoke-WingetReinstall {
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Id
    )
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { Write-Warning "winget not found."; return }
    Write-Host "Reinstalling $Id (requesting elevation)..." -ForegroundColor Cyan

    # Write to a temp script so the elevated process can poll until uninstall actually finishes
    $script = [System.IO.Path]::GetTempFileName() + '.ps1'
    Set-Content $script @"
winget uninstall --id '$Id' --accept-source-agreements --all-versions --interactive
Write-Host 'Waiting for uninstall to complete...' -ForegroundColor Yellow
do { Start-Sleep 2 } until (-not (winget list --id '$Id' | Out-String | Select-String '$Id'))
winget install -e --id '$Id' --accept-package-agreements --accept-source-agreements --interactive
"@
    Start-Process powershell -Verb RunAs -WindowStyle Hidden -ArgumentList "-NoProfile", "-File", $script -Wait
    Remove-Item $script -ErrorAction SilentlyContinue
    Write-Host "$Id reinstalled successfully." -ForegroundColor Green
}
Set-Alias -Name winget-reinstall -Value Invoke-WingetReinstall
