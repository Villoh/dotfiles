# GUI installer for Villoh/dotfiles on Windows (the CLI flow is install.ps1).
# In any PowerShell:
#
#   irm https://raw.githubusercontent.com/Villoh/dotfiles/main/install-gui.ps1 | iex
#
# Relaunches itself as Administrator (winget and run_once_00_windows-install
# expect it), downloads the installer GUI from the latest GitHub release,
# checks its SHA-256 against the release's SHA256SUMS, and runs it.
# Runs in Windows PowerShell 5.1 and PowerShell 7. Never `exit`: under iex it
# would close the user's terminal.

& {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'  # Invoke-WebRequest crawls with a progress bar in 5.1
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    $repo    = 'Villoh/dotfiles'
    $self    = "https://raw.githubusercontent.com/$repo/main/install-gui.ps1"
    $base    = "https://github.com/$repo/releases/latest/download"
    $exeName = 'dotfiles-installer.exe'

    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host 'Relaunching as Administrator (accept the UAC prompt)...' -ForegroundColor Cyan
        Start-Process powershell.exe -Verb RunAs -ArgumentList @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', "irm '$self' | iex")
        return
    }

    $dir = Join-Path $env:TEMP 'dotfiles-installer'
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $exe  = Join-Path $dir $exeName
    $sums = Join-Path $dir 'SHA256SUMS'

    Write-Host "Downloading $exeName..." -ForegroundColor Cyan
    Invoke-WebRequest "$base/$exeName" -OutFile $exe -UseBasicParsing
    Invoke-WebRequest "$base/SHA256SUMS" -OutFile $sums -UseBasicParsing

    # sha256sum lines: "<hex>  <name>" (or "<hex> *<name>" in binary mode)
    $line = Get-Content $sums | Where-Object { $_ -match "^[0-9a-fA-F]{64}\s+\*?$([regex]::Escape($exeName))$" } |
        Select-Object -First 1
    if (-not $line) { Remove-Item $exe; throw "SHA256SUMS has no entry for $exeName" }
    $expected = ($line -split '\s+')[0]
    $actual   = (Get-FileHash $exe -Algorithm SHA256).Hash
    if ($actual -ne $expected) { Remove-Item $exe; throw "SHA-256 mismatch for ${exeName}: expected $expected, got $actual" }

    Write-Host 'Checksum OK. Starting the installer...' -ForegroundColor Green
    Start-Process $exe -Wait
}
