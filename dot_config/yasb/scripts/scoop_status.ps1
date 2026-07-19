$ErrorActionPreference = "SilentlyContinue"

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




