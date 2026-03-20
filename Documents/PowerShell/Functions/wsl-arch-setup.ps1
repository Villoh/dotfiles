function Setup-WslArch {
    <#
    .SYNOPSIS
        Installs Arch Linux in WSL and sets up packages from wsl-pacman/aur-packages.txt.
    .DESCRIPTION
        1. Checks WSL is available
        2. Installs Arch distro if missing (opens interactive terminal for first-time setup)
        3. Configures locale (en_US.UTF-8)
        4. Installs pacman packages from wsl-pacman-packages.txt
        5. Bootstraps paru and installs AUR packages from wsl-aur-packages.txt
    #>
    $srcDir   = chezmoi source-path
    $pacFile  = Join-Path $srcDir "packages\windows\wsl-pacman-packages.txt"
    $aurFile  = Join-Path $srcDir "packages\windows\wsl-aur-packages.txt"

    # -- Step 1: WSL available? ------------------------------------------------
    if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
        Write-Warning "WSL not found. Install it first:"
        Write-Host "  winget install --id Microsoft.WSL -e" -ForegroundColor Cyan
        Write-Host "  Reboot, then run setup-wsl-arch again." -ForegroundColor Cyan
        return
    }

    # -- Step 2: Arch distro installed? ----------------------------------------
    $archInstalled = wsl -l -v 2>$null | Select-String -Pattern "Arch" -Quiet
    if (-not $archInstalled) {
        Write-Host "Installing Arch Linux WSL..." -ForegroundColor Cyan
        wsl --install -d Arch
        Write-Host "`nArch WSL installed. Opening terminal for first-time setup..." -ForegroundColor Green
        Write-Host "  Create your user and set a password when prompted." -ForegroundColor Yellow
        Start-Process wt -ArgumentList "wsl -d Arch"
        Read-Host "`nComplete the Arch setup in the terminal, then press Enter to continue"
    } else {
        Write-Host "[SKIP] Arch already in WSL" -ForegroundColor Yellow
    }

    # -- Step 3: Locale --------------------------------------------------------
    Write-Host "`nConfiguring locale..." -ForegroundColor Cyan
    wsl -d Arch -u root -- bash -c "sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen && echo 'LANG=en_US.UTF-8' > /etc/locale.conf"
    Write-Host "[OK] Locale configured" -ForegroundColor Green

    # -- Step 4: pacman packages -----------------------------------------------
    if (Test-Path $pacFile) {
        $pacPkgs = Get-Content $pacFile | Where-Object { $_.Trim() -ne "" -and -not $_.StartsWith("#") }
        if ($pacPkgs) {
            Write-Host "`nUpdating pacman..." -ForegroundColor Cyan
            wsl -d Arch -u root -- pacman -Syu --noconfirm
            foreach ($pkg in $pacPkgs) {
                $installed = wsl -d Arch -u root -- pacman -Qi $pkg 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  [SKIP] $pkg" -ForegroundColor Yellow
                } else {
                    wsl -d Arch -u root -- pacman -S --noconfirm $pkg
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "  [OK]   $pkg" -ForegroundColor Green
                    } else {
                        Write-Host "  [FAIL] $pkg" -ForegroundColor Red
                    }
                }
            }
        }
    }

    # -- Step 5: paru bootstrap + AUR packages ---------------------------------
    if (Test-Path $aurFile) {
        $aurPkgs = Get-Content $aurFile | Where-Object { $_.Trim() -ne "" -and -not $_.StartsWith("#") }
        if ($aurPkgs) {
            Write-Host "`nBootstrapping paru (AUR helper)..." -ForegroundColor Cyan
            wsl -d Arch -- bash -c @'
command -v paru && exit 0
sudo pacman -S --noconfirm --needed base-devel git
git clone https://aur.archlinux.org/paru-bin.git /tmp/paru-bin
cd /tmp/paru-bin && makepkg -si --noconfirm
rm -rf /tmp/paru-bin
'@
            foreach ($pkg in $aurPkgs) {
                $installed = wsl -d Arch -- bash -c "paru -Qi $pkg 2>/dev/null; echo `$?"
                if ($installed -match "^0$") {
                    Write-Host "  [SKIP] $pkg" -ForegroundColor Yellow
                } else {
                    wsl -d Arch -- paru -S --noconfirm $pkg
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "  [OK]   $pkg" -ForegroundColor Green
                    } else {
                        Write-Host "  [FAIL] $pkg" -ForegroundColor Red
                    }
                }
            }
        }
    }

    Write-Host "`nDone. Run 'wsl -d Arch' to open your Arch shell." -ForegroundColor Green
}

Set-Alias -Name setup-wsl-arch -Value Setup-WslArch
