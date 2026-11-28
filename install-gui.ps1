# GUI installer for Villoh/dotfiles on Windows (the CLI flow is install.ps1).
# In any PowerShell:
#
#   irm https://raw.githubusercontent.com/Villoh/dotfiles/main/install-gui.ps1 | iex
#
# Downloads the installer GUI from the latest GitHub release and checks its
# SHA-256 against the release's SHA256SUMS, all in this terminal, not elevated.
# Only the installer itself is started as Administrator (winget and
# run_once_00_windows-install expect it): one UAC prompt, no second terminal.
# It starts without waiting: the terminal is free once the installer opens.
# Runs in Windows PowerShell 5.1 and PowerShell 7. Never `exit`: under iex it
# would close the user's terminal.

& {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'  # Invoke-WebRequest crawls with a progress bar in 5.1
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    $repo    = 'Villoh/dotfiles'
    $base    = "https://github.com/$repo/releases/latest/download"
    $exeName = 'dotfiles-installer.exe'

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

    Write-Host 'Checksum OK. Starting the installer (accept the UAC prompt)...' -ForegroundColor Green
    try {
        Start-Process $exe -Verb RunAs
    } catch {
        # Declining the UAC prompt lands here.
        throw "The installer was not started: it needs Administrator rights. $($_.Exception.Message)"
    }
    Write-Host 'The installer runs in its own window; this terminal is free.' -ForegroundColor Green
}
