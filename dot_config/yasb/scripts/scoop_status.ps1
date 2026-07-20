$ErrorActionPreference = "SilentlyContinue"

# Refresh bucket manifests via git every 3h so 'scoop status -l' (local, no network)
# has current data. Keeps most polls instant while staying reasonably fresh.
$scoopConfig = "$env:USERPROFILE\.config\scoop\config.json"
$maxAge = New-TimeSpan -Hours 3
if (Test-Path $scoopConfig) {
    try {
        $lastUpdate = [datetime](Get-Content $scoopConfig -Raw | ConvertFrom-Json).last_update
        if ((Get-Date) - $lastUpdate -gt $maxAge) {
            scoop update 6>$null 3>$null | Out-Null
        }
    }
    catch {
        scoop update 6>$null 3>$null | Out-Null
    }
}
else {
    scoop update 6>$null 3>$null | Out-Null
}

$outdated = scoop status -l 6>$null
$apps = @($outdated | ForEach-Object {
        [PSCustomObject]@{
            name      = $_.Name
            installed = $_."Installed Version"
            latest    = $_."Latest Version"
        }
    })

$tooltipLines = $apps | ForEach-Object { "$($_.name): $($_.installed) -> $($_.latest)" }
$tooltip = if ($tooltipLines.Count -gt 0) { "Scoop Update`n`n" + ($tooltipLines -join "`n") } else { "Scoop Update`n`nUp to date" }

if ($apps.Count -eq 0) {
    # empty output -> yasb JSON parse fails -> exec_data becomes null -> hide_empty hides the widget
    Write-Output ""
}
else {
    @{ count = $apps.Count; apps = $apps; tooltip = $tooltip } | ConvertTo-Json -Compress
}




