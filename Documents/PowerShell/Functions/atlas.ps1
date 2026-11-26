# Atlas (https://atlasos.net) is applied by AtlasManager.exe, a GUI that updates Windows, restarts the PC and
# needs four Windows Security switches turned off by hand, so it is never part of `chezmoi apply`.
# This opens the pinned Manager for an update or a reinstall on a machine that already has these dotfiles.
# A first install happens before chezmoi exists: see docs/install/windows-atlas.md.

<#
.SYNOPSIS
    Downloads AtlasManager.exe at the version pinned in packages/windows/system/atlas.json, checks its
    SHA-256 and opens it.
.PARAMETER Path
    Only download and verify; print the path and do not open it.
.EXAMPLE
    Install-Atlas
#>
function Install-Atlas {
    param ([switch] $Path)

    $atlas = Get-Content "$(chezmoi source-path)\packages\windows\system\atlas.json" | ConvertFrom-Json

    # Atlas does not support Home, LTSC or Server (EditionID Core*, ending in S, Server*).
    $edition = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").EditionID
    if ($edition -match '^Core|S$|^Server') {
        Write-Warning "Windows edition '$edition' is not supported by Atlas (use Pro, Education or Enterprise)."
    }

    if (Test-Path "$env:windir\AtlasOS") {
        Write-Host "Atlas is already installed: in Atlas Manager choose 'Update to Atlas' and 'Keep my choices'." -ForegroundColor Yellow
    } else {
        Write-Host "Atlas is meant for a fresh Windows 11: it removes OneDrive and reboots. Back up first." -ForegroundColor Yellow
    }

    $exe = Join-Path $env:TEMP "AtlasManager-$($atlas.version).exe"
    if (-not (Test-Path $exe)) {
        Invoke-WebRequest -Uri $atlas.url -OutFile $exe -UseBasicParsing
    }
    $hash = (Get-FileHash $exe -Algorithm SHA256).Hash
    if ($hash -ne $atlas.sha256.ToUpper()) {
        Remove-Item $exe -ErrorAction SilentlyContinue
        Write-Error "SHA-256 mismatch for AtlasManager $($atlas.version) (got $hash)"
        return
    }
    Write-Host "AtlasManager $($atlas.version) verified." -ForegroundColor Green

    if ($Path) { return $exe }
    Start-Process -FilePath $exe
}

Set-Alias -Name install-atlas -Value Install-Atlas
