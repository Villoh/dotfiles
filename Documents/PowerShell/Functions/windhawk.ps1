function Restore-Windhawk {
    <#
    .SYNOPSIS
        Imports Windhawk settings from the chezmoi source registry file.
    .DESCRIPTION
        Windhawk must be fully closed before running this. Install all desired
        mods first, then close Windhawk, then run this function.
    #>
    $windhawk = Get-Process -Name "Windhawk*" -ErrorAction SilentlyContinue
    if ($windhawk) {
        Write-Warning "Windhawk is running. Close it first, then run Restore-Windhawk again."
        return
    }

    $regFile = (Join-Path (chezmoi source-path) "packages\windows\windhawk-settings.reg")
    if (-not (Test-Path $regFile)) {
        Write-Warning "Registry file not found: $regFile"
        return
    }

    $cmd = "reg import `"$regFile`"; Write-Host 'Windhawk settings imported.' -ForegroundColor Green; Read-Host '`nPress Enter to close'"
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile", "-Command", $cmd -Wait
}

Set-Alias -Name restore-windhawk -Value Restore-Windhawk
