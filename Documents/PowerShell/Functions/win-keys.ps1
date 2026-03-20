# ============================================================
# Win Key Modifier — GlazeWM helpers
# Add this to your PowerShell $PROFILE:
#   . "$HOME\.config\windows-tweaks\win-keys.ps1"
# ============================================================

$_WinKeysRegistryKey   = "NoWinKeys"
$_WinKeysRegistryPaths = @{
    User   = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
    System = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
}

<#
.SYNOPSIS
    Disables all Windows key shortcuts so GlazeWM can use WIN as modifier.
.PARAMETER Scope
    User   — writes to HKCU (current user only).
    System — writes to HKLM (all users, requires elevation).
    Default: System.
.EXAMPLE
    Disable-WinKeys
    Disable-WinKeys -Scope User
#>
function Disable-WinKeys {
    param (
        [ValidateSet("User", "System")]
        [string] $Scope = "System"
    )

    Write-Host "Disabling Windows key shortcuts [$Scope]..." -ForegroundColor Yellow
    if (-not (_Set-WinKeysValue -Value 1 -Scope $Scope)) { return }
    _Restart-Explorer
    Write-Host "Done. WIN key is now free for GlazeWM." -ForegroundColor Green
    Write-Host "Run Enable-WinKeys to restore defaults." -ForegroundColor DarkGray
}

<#
.SYNOPSIS
    Restores all default Windows key shortcuts.
.PARAMETER Scope
    User   — writes to HKCU (current user only).
    System — writes to HKLM (all users, requires elevation).
    Default: System.
.EXAMPLE
    Enable-WinKeys
    Enable-WinKeys -Scope User
#>
function Enable-WinKeys {
    param (
        [ValidateSet("User", "System")]
        [string] $Scope = "System"
    )

    Write-Host "Restoring Windows key shortcuts [$Scope]..." -ForegroundColor Yellow
    if (-not (_Set-WinKeysValue -Value 0 -Scope $Scope)) { return }
    _Restart-Explorer
    Write-Host "Done. Windows key shortcuts restored." -ForegroundColor Green
}

<#
.SYNOPSIS
    Shows current status of Windows key shortcuts.
.PARAMETER Scope
    User   — reads from HKCU.
    System — reads from HKLM.
    Default: System.
.EXAMPLE
    Get-WinKeysStatus
    Get-WinKeysStatus -Scope User
#>
function Get-WinKeysStatus {
    param (
        [ValidateSet("User", "System")]
        [string] $Scope = "System"
    )

    $value = _Get-WinKeysValue -Scope $Scope
    $label = "[$Scope]"

    if ($null -eq $value -or $value -eq 0) {
        Write-Host "WIN keys ${label}: ENABLED (default)" -ForegroundColor Green
    } else {
        Write-Host "WIN keys ${label}: DISABLED (GlazeWM mode)" -ForegroundColor Yellow
    }
}

# ============================================================
# Internal helpers
# ============================================================

<#
.SYNOPSIS
    Reads NoWinKeys from the registry path matching the given scope.
.NOTES
    Internal helper — not exported.
#>
function _Get-WinKeysValue {
    param (
        [Parameter(Mandatory)]
        [ValidateSet("User", "System")]
        [string] $Scope
    )

    $path  = $_WinKeysRegistryPaths[$Scope]
    $entry = Get-ItemProperty `
        -Path  $path `
        -Name  $_WinKeysRegistryKey `
        -ErrorAction SilentlyContinue

    return $entry.$_WinKeysRegistryKey
}

<#
.SYNOPSIS
    Writes NoWinKeys to the registry path matching the given scope.
    Elevates automatically when writing to System (HKLM).
.NOTES
    Internal helper — not exported.
#>
function _Set-WinKeysValue {
    param (
        [Parameter(Mandatory)]
        [ValidateSet(0, 1)]
        [int] $Value,

        [Parameter(Mandatory)]
        [ValidateSet("User", "System")]
        [string] $Scope
    )

    $path    = $_WinKeysRegistryPaths[$Scope]
    $isAdmin = ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)

    if ($Scope -eq "System" -and -not $isAdmin) {
        $cmd = "if (-not (Test-Path '$path')) { New-Item -Path '$path' -Force | Out-Null }; " +
               "Set-ItemProperty -Path '$path' -Name '$_WinKeysRegistryKey' -Value $Value -Type DWord"
        try {
            Start-Process powershell `
                -Verb RunAs `
                -WindowStyle Hidden `
                -ArgumentList "-NoProfile -Command $cmd" `
                -Wait -ErrorAction Stop
        } catch {
            Write-Warning "Elevation cancelled or failed. Registry not updated."
            return $false
        }
    } else {
        try {
            if (-not (Test-Path $path)) { New-Item -Path $path -Force -ErrorAction Stop | Out-Null }
            Set-ItemProperty -Path $path -Name $_WinKeysRegistryKey -Value $Value -Type DWord -ErrorAction Stop
        } catch {
            Write-Warning "Failed to update registry: $($_.Exception.Message)"
            return $false
        }
    }
    return $true
}

<#
.SYNOPSIS
    Restarts Windows Explorer to apply registry changes immediately.
.NOTES
    Internal helper — not exported.
#>
function _Restart-Explorer {
    Write-Host "Restarting Explorer..." -ForegroundColor DarkGray

    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 1000
    Start-Process explorer
    Start-Sleep -Milliseconds 800
    Write-Host "Explorer restarted." -ForegroundColor DarkGray
}

# ============================================================
# Aliases
# ============================================================
Set-Alias disable-win-keys Disable-WinKeys
Set-Alias enable-win-keys  Enable-WinKeys
Set-Alias win-keys-status  Get-WinKeysStatus
