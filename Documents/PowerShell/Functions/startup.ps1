# ============================================================
# Startup Entries Manager - manage startup.json entries
# ============================================================

$_StartupJsonPath = "$(chezmoi source-path)\packages\windows\system\startup.json"
$_StartupRunKey   = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$_StartupMsixBase = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\SystemAppData"

<#
.SYNOPSIS
    Lists all startup entries from startup.json and their current state.
.EXAMPLE
    Get-StartupEntries
#>
function Get-StartupEntries {
    $entries = _Get-AllStartupEntries
    if (-not $entries) { return }

    foreach ($e in $entries) {
        $color = switch ($e.State) {
            "ENABLED"      { "Green"  }
            "DISABLED"     { "DarkGray" }
            default        { "Yellow" }
        }
        Write-Host "  [$($e.Type)] $($e.Name): $($e.State)" -ForegroundColor $color
    }
}

<#
.SYNOPSIS
    Disables one or more startup entries. Picks interactively via fzf if no name given.
.PARAMETER Name
    Name of the entry as defined in startup.json. Optional — omit to pick with fzf.
.EXAMPLE
    Disable-StartupEntry
    Disable-StartupEntry MicaForEveryone
#>
function Disable-StartupEntry {
    param (
        [Parameter(Position = 0)]
        [string] $Name
    )

    $targets = _Resolve-StartupEntries -Name $Name -FilterState "ENABLED" -Prompt "Disable startup entry"
    if (-not $targets) { return }

    foreach ($e in $targets) { _Set-StartupEntryState $e $false }
}

<#
.SYNOPSIS
    Enables one or more startup entries. Picks interactively via fzf if no name given.
.PARAMETER Name
    Name of the entry as defined in startup.json. Optional — omit to pick with fzf.
.EXAMPLE
    Enable-StartupEntry
    Enable-StartupEntry MicaForEveryone
#>
function Enable-StartupEntry {
    param (
        [Parameter(Position = 0)]
        [string] $Name
    )

    $targets = _Resolve-StartupEntries -Name $Name -FilterState "DISABLED" -Prompt "Enable startup entry"
    if (-not $targets) { return }

    foreach ($e in $targets) { _Set-StartupEntryState $e $true }
}

# ============================================================
# Internal helpers
# ============================================================

function _Get-AllStartupEntries {
    $cfg = _Get-StartupConfig
    if (-not $cfg) { return $null }

    $entries = @()

    foreach ($e in $cfg.registry) {
        $val   = (Get-ItemProperty -Path $_StartupRunKey -Name $e.name -ErrorAction SilentlyContinue).($e.name)
        $state = if ($val) { "ENABLED" } else { "DISABLED" }
        $entries += [PSCustomObject]@{ Name = $e.name; Type = "registry"; State = $state; Raw = $e }
    }

    foreach ($e in $cfg.msix) {
        $state   = _Get-MsixStartupState $e.package
        $entries += [PSCustomObject]@{ Name = $e.name; Type = "msix"; State = $state; Raw = $e }
    }

    $startupFolder = [System.Environment]::GetFolderPath("Startup")
    foreach ($e in $cfg.folder) {
        $lnk   = "$startupFolder\$($e.name).lnk"
        $state = if (Test-Path $lnk) { "ENABLED" } else { "DISABLED" }
        $entries += [PSCustomObject]@{ Name = $e.name; Type = "folder"; State = $state; Raw = $e }
    }

    return $entries
}

function _Resolve-StartupEntries {
    param (
        [string] $Name,
        [string] $FilterState,
        [string] $Prompt
    )

    $all = _Get-AllStartupEntries
    if (-not $all) { return $null }

    if ($Name) {
        $match = $all | Where-Object { $_.Name -eq $Name }
        if (-not $match) { Write-Warning "'$Name' not found in startup.json."; return $null }
        return @($match)
    }

    # Interactive fzf / Out-GridView selection
    $candidates = $all | Where-Object { $_.State -eq $FilterState -or $FilterState -eq "" }
    if (-not $candidates) {
        Write-Host "No entries with state '$FilterState' found." -ForegroundColor DarkGray
        return $null
    }

    $lines = $candidates | ForEach-Object { "$($_.Name)  [$($_.Type)]  $($_.State)" }

    if (Get-Command fzf -ErrorAction SilentlyContinue) {
        $selected = $lines | fzf --multi --prompt="$Prompt > " --height=40% --border
    } else {
        $selected = $lines | Out-GridView -Title $Prompt -PassThru
    }

    if (-not $selected) { Write-Host "No entry selected." -ForegroundColor DarkGray; return $null }

    # Map selected lines back to entry objects
    return $selected | ForEach-Object {
        $selName = ($_ -split '\s{2,}')[0]
        $all | Where-Object { $_.Name -eq $selName }
    }
}

function _Set-StartupEntryState {
    param (
        [PSCustomObject] $Entry,
        [bool] $Enable
    )

    switch ($Entry.Type) {
        "registry" {
            if ($Enable) {
                $expanded = [System.Environment]::ExpandEnvironmentVariables($Entry.Raw.path)
                $value    = if ($Entry.Raw.args) { "`"$expanded`" $($Entry.Raw.args)" } else { "`"$expanded`"" }
                Set-ItemProperty -Path $_StartupRunKey -Name $Entry.Name -Value $value -Type String
                Write-Host "$($Entry.Name) enabled (HKCU\Run)." -ForegroundColor Green
            } else {
                Remove-ItemProperty -Path $_StartupRunKey -Name $Entry.Name -ErrorAction SilentlyContinue
                Write-Host "$($Entry.Name) disabled (HKCU\Run entry removed)." -ForegroundColor Yellow
            }
        }
        "msix" {
            $taskKey = _Get-MsixStartupKey $Entry.Raw.package
            if (-not $taskKey) {
                Write-Warning "$($Entry.Name): startup task key not found (activate the app first so Windows registers it)."
                return
            }
            $state = if ($Enable) { 2 } else { 0 }
            Set-ItemProperty -Path $taskKey.PSPath -Name State -Value $state -Type DWord
            $verb = if ($Enable) { "enabled (State=2)" } else { "disabled (State=0)" }
            $color = if ($Enable) { "Green" } else { "Yellow" }
            Write-Host "$($Entry.Name) $verb (MSIX startup task)." -ForegroundColor $color
        }
        "folder" {
            $startupFolder = [System.Environment]::GetFolderPath("Startup")
            $lnk           = "$startupFolder\$($Entry.Name).lnk"
            if ($Enable) {
                $expanded = [System.Environment]::ExpandEnvironmentVariables($Entry.Raw.path)
                if (-not (Test-Path $expanded)) { Write-Warning "$($Entry.Name): exe not found at $expanded"; return }
                $shell    = New-Object -ComObject WScript.Shell
                $shortcut = $shell.CreateShortcut($lnk)
                $shortcut.TargetPath = $expanded
                if ($Entry.Raw.args) { $shortcut.Arguments = $Entry.Raw.args }
                $shortcut.Save()
                Write-Host "$($Entry.Name) enabled (startup folder shortcut)." -ForegroundColor Green
            } else {
                Remove-Item $lnk -Force -ErrorAction SilentlyContinue
                Write-Host "$($Entry.Name) disabled (startup folder shortcut removed)." -ForegroundColor Yellow
            }
        }
    }
}

function _Get-StartupConfig {
    if (-not (Test-Path $_StartupJsonPath)) {
        Write-Warning "startup.json not found at $_StartupJsonPath"
        return $null
    }
    return Get-Content $_StartupJsonPath | ConvertFrom-Json
}

function _Get-MsixStartupKey {
    param ([string] $PackageName)
    $pkg = Get-AppxPackage -Name "*$PackageName*" -ErrorAction SilentlyContinue
    if (-not $pkg) { return $null }
    return Get-ChildItem "$_StartupMsixBase\$($pkg.PackageFamilyName)" -ErrorAction SilentlyContinue |
        Where-Object { $null -ne $_.GetValue("State") } | Select-Object -First 1
}

function _Get-MsixStartupState {
    param ([string] $PackageName)
    $pkg = Get-AppxPackage -Name "*$PackageName*" -ErrorAction SilentlyContinue
    if (-not $pkg) { return "NOT INSTALLED" }
    $key = _Get-MsixStartupKey $PackageName
    if (-not $key) { return "NO TASK KEY" }
    $stateVal = $key.GetValue("State")
    switch ($stateVal) {
        2       { return "ENABLED" }
        0       { return "DISABLED" }
        1       { return "DISABLED (policy)" }
        default { return "UNKNOWN ($stateVal)" }
    }
}

# ============================================================
# Aliases
# ============================================================
Set-Alias startup-entries  Get-StartupEntries
Set-Alias disable-startup  Disable-StartupEntry
Set-Alias enable-startup   Enable-StartupEntry
