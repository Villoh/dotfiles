function Invoke-WslSetup {
    <#
    .SYNOPSIS
        Installs a WSL distro (selected via fzf) and sets up packages.
    .DESCRIPTION
        1. Checks WSL is available
        2. Lists available distros via fzf for selection
        3. Installs selected distro if missing (opens interactive terminal for first-time setup)
        4. Arch-specific: configures locale, installs pacman/AUR packages
    #>
    $srcDir  = chezmoi source-path

    # -- Step 1: WSL available? ------------------------------------------------
    if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
        Write-Warning "WSL not found. Install it first:"
        Write-Host "  winget install --id Microsoft.WSL -e" -ForegroundColor Cyan
        Write-Host "  Reboot, then run setup-wsl again." -ForegroundColor Cyan
        return
    }

    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
        Write-Warning "fzf not found. Install it first: scoop install fzf"
        return
    }

    # -- Step 2: Pick distro via fzf -------------------------------------------
    # wsl outputs UTF-16 LE; set OutputEncoding so PowerShell decodes it correctly
    $prevEncoding = [Console]::OutputEncoding
    [Console]::OutputEncoding = [System.Text.Encoding]::Unicode
    $onlineRaw = wsl --list --online 2>$null
    $wslList   = wsl --list 2>$null
    [Console]::OutputEncoding = $prevEncoding

    $distros = $onlineRaw |
        Where-Object { $_ -match '^\s*[A-Za-z]' -and $_ -notmatch '^NAME\s|following|Install using' } |
        ForEach-Object { ($_ -split '\s{2,}')[0].Trim() } |
        Where-Object { $_ -ne "" }

    if (-not $distros) {
        Write-Warning "Could not fetch distro list. Check internet connection."
        return
    }

    $selected = $distros | fzf --prompt="Select WSL distro > " --height=40% --border
    if (-not $selected) {
        Write-Host "No distro selected. Aborting." -ForegroundColor Yellow
        return
    }

    # -- Step 3: Already installed? --------------------------------------------
    if ($wslList -match [regex]::Escape($selected)) {
        Write-Host "[SKIP] $selected already installed" -ForegroundColor Yellow
    } else {
        Write-Host "Installing $selected..." -ForegroundColor Cyan
        wsl --install -d $selected --no-launch

        # Check if distro is now usable (reboot may be needed)
        $prevEnc = [Console]::OutputEncoding
        [Console]::OutputEncoding = [System.Text.Encoding]::Unicode
        $newList = wsl --list 2>$null
        [Console]::OutputEncoding = $prevEnc
        if (-not ($newList -match [regex]::Escape($selected))) {
            Write-Host "`n[!] Reboot required to complete WSL setup." -ForegroundColor Yellow
            Write-Host "    After rebooting, run 'setup-wsl' again." -ForegroundColor Yellow
            return
        }

        if ($selected -match "Arch") {
            $wslUser = $env:USERNAME.ToLower()
            Write-Host "`nCreating user '$wslUser' in $selected..." -ForegroundColor Cyan
            wsl -d $selected -u root -- bash -c "useradd -m -G wheel -s /bin/bash $wslUser && printf '[user]\ndefault=$wslUser\n' > /etc/wsl.conf"
            Write-Host "[OK] User '$wslUser' created. Run 'passwd' inside WSL to set a password." -ForegroundColor Green
            # Restart distro so wsl.conf default user takes effect
            wsl --terminate $selected 2>$null
        }
    }

    # -- Step 4: Distro-specific setup -----------------------------------------
    if ($selected -match "Arch") {
        $pacFile = Join-Path $srcDir "packages\windows\wsl\pacman-packages.txt"
        $aurFile = Join-Path $srcDir "packages\windows\wsl\aur-packages.txt"

        # Keyring init (required on first launch)
        Write-Host "`nInitializing pacman keyring..." -ForegroundColor Cyan
        wsl -d $selected -u root -- bash -c "pacman-key --init && pacman-key --populate archlinux"
        Write-Host "[OK] Keyring ready" -ForegroundColor Green

        # Locale
        Write-Host "`nConfiguring locale..." -ForegroundColor Cyan
        wsl -d $selected -u root -- bash -c "sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen && echo 'LANG=en_US.UTF-8' > /etc/locale.conf"
        Write-Host "[OK] Locale configured" -ForegroundColor Green

        # pacman packages
        if (Test-Path $pacFile) {
            $pacPkgs = Get-Content $pacFile | Where-Object { $_.Trim() -ne "" -and -not $_.StartsWith("#") }
            if ($pacPkgs) {
                Write-Host "`nUpdating pacman..." -ForegroundColor Cyan
                wsl -d $selected -u root -- pacman -Syu --noconfirm
                foreach ($pkg in $pacPkgs) {
                    wsl -d $selected -u root -- pacman -Qi $pkg 2>$null | Out-Null
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "  [SKIP] $pkg" -ForegroundColor Yellow
                    } else {
                        wsl -d $selected -u root -- pacman -S --noconfirm $pkg
                        if ($LASTEXITCODE -eq 0) {
                            Write-Host "  [OK]   $pkg" -ForegroundColor Green
                        } else {
                            Write-Host "  [FAIL] $pkg" -ForegroundColor Red
                        }
                    }
                }
            }
        }

        # paru + AUR packages
        if (Test-Path $aurFile) {
            $aurPkgs = Get-Content $aurFile | Where-Object { $_.Trim() -ne "" -and -not $_.StartsWith("#") }
            if ($aurPkgs) {
                # Get default WSL user (non-root)
                $wslUser = (wsl -d $selected -- whoami 2>$null).Trim()

                Write-Host "`nBootstrapping paru (AUR helper)..." -ForegroundColor Cyan

                # Install sudo + git + base-devel as root, configure sudoers
                wsl -d $selected -u root -- pacman -S --noconfirm --needed sudo git base-devel
                wsl -d $selected -u root -- bash -c "usermod -aG wheel $wslUser && mkdir -p /etc/sudoers.d && echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/wheel && chmod 440 /etc/sudoers.d/wheel"

                # Bootstrap paru from source as the default user
                wsl -d $selected -u $wslUser -- bash -c @'
paru --version >/dev/null 2>&1 && exit 0
sudo pacman -Rns paru paru-bin --noconfirm 2>/dev/null; true
rm -rf /tmp/paru
git clone https://aur.archlinux.org/paru.git /tmp/paru
cd /tmp/paru && makepkg -si --noconfirm
rm -rf /tmp/paru
'@
                foreach ($pkg in $aurPkgs) {
                    wsl -d $selected -u $wslUser -- paru -Qi $pkg 2>$null | Out-Null
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "  [SKIP] $pkg" -ForegroundColor Yellow
                    } else {
                        wsl -d $selected -u $wslUser -- paru -S --noconfirm $pkg
                        if ($LASTEXITCODE -eq 0) {
                            Write-Host "  [OK]   $pkg" -ForegroundColor Green
                        } else {
                            Write-Host "  [FAIL] $pkg" -ForegroundColor Red
                        }
                    }
                }
            }
        }
    } else {
        Write-Host "`nNo additional package setup available for $selected." -ForegroundColor Yellow
        Write-Host "Add distro-specific steps to wsl-arch-setup.ps1 if needed." -ForegroundColor DarkGray
    }

    Write-Host "`nDone. Run 'wsl -d $selected' to open your shell." -ForegroundColor Green
}

Set-Alias -Name setup-wsl -Value Invoke-WslSetup
