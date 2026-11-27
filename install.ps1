# One-shot CLI installer for Villoh/dotfiles on Windows. In any PowerShell:
#
#   irm https://raw.githubusercontent.com/Villoh/dotfiles/main/install.ps1 | iex
#
# Terminal only (the GUI flow is install-gui.ps1). Follows
# docs/install/bootstrap.md: installs Git, Gpg4win and chezmoi with winget,
# runs chezmoi init (its own prompts), imports the GPG key for the personal
# flow, seeds the GPG/SSH agent files, checks decryption with chezmoi diff,
# and runs chezmoi apply, whose scripts ask for packages with fzf.
# Runs in Windows PowerShell 5.1 and PowerShell 7. Never `exit`: under iex it
# would close the user's terminal.

& {
    $ErrorActionPreference = 'Stop'
    $repo = 'Villoh/dotfiles'
    $self = "https://raw.githubusercontent.com/$repo/main/install.ps1"

    function Step { param([string]$msg) Write-Host "`n== $msg" -ForegroundColor Cyan }
    function Refresh-Path {
        $env:PATH = [Environment]::GetEnvironmentVariable('PATH', 'Machine') + ';' +
                    [Environment]::GetEnvironmentVariable('PATH', 'User')
    }
    # Native commands do not throw on failure; this does.
    function Invoke-Checked {
        param([string]$what, [scriptblock]$block)
        & $block
        if ($LASTEXITCODE -ne 0) { throw "$what failed (exit $LASTEXITCODE)" }
    }
    # Runs a native command silently and returns its exit code. In 5.1, stderr
    # redirected under ErrorActionPreference=Stop would throw.
    function Test-Quiet {
        param([scriptblock]$block)
        $ErrorActionPreference = 'Continue'
        & $block *> $null
        return $LASTEXITCODE
    }

    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host 'Relaunching as Administrator (accept the UAC prompt)...' -ForegroundColor Cyan
        Start-Process powershell.exe -Verb RunAs -ArgumentList @(
            '-NoExit', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', "irm '$self' | iex")
        return
    }

    # -- 1. Bootstrap tools --------------------------------------------------
    Step 'Bootstrap tools'
    foreach ($t in @(
            @{ Exe = 'git';     Id = 'Git.Git' },
            @{ Exe = 'gpg';     Id = 'GnuPG.Gpg4win' },
            @{ Exe = 'chezmoi'; Id = 'twpayne.chezmoi'; Scope = 'machine' })) {
        if (Get-Command $t.Exe -ErrorAction SilentlyContinue) {
            Write-Host "  [SKIP] $($t.Id) already installed" -ForegroundColor Yellow
            continue
        }
        # chezmoi is a portable package (user scope by default): winget refuses those from this
        # elevated session (0x8a15007d), so it asks for the machine scope.
        $scope = if ($t.Scope) { @('--scope', $t.Scope) } else { @() }
        Invoke-Checked "winget install $($t.Id)" {
            winget install -e --id $t.Id @scope --accept-package-agreements --accept-source-agreements
        }
        Refresh-Path
    }
    # Gpg4win's bin is what .chezmoi.toml.tmpl configures; put it first.
    $gpgBin = 'C:\Program Files\GnuPG\bin'
    if (Test-Path $gpgBin) { $env:PATH = "$gpgBin;$env:PATH" }
    foreach ($exe in 'git', 'gpg', 'chezmoi') {
        if (-not (Get-Command $exe -ErrorAction SilentlyContinue)) {
            throw "$exe not found after installing it; open a new terminal and run the installer again"
        }
    }

    # -- 2. Flow -----------------------------------------------------------------
    Step 'Flow'
    Write-Host '  1) Personal:  decrypt the encrypted files with my GPG key'
    Write-Host '  2) Secondary: skip encrypted files (identities, work config, secrets)'
    do { $choice = Read-Host '  Choose 1 or 2' } until ($choice -in '1', '2')
    $personal = $choice -eq '1'

    # -- 3. chezmoi init (clones, asks the install profile and modules) --------
    Step 'chezmoi init'
    Invoke-Checked 'chezmoi init' { chezmoi init "https://github.com/$repo" }
    $src = chezmoi source-path
    if ($LASTEXITCODE -ne 0 -or -not $src) { throw 'chezmoi source-path failed' }

    if ($personal) {
        # -- 4. GPG key -----------------------------------------------------------
        Step 'GPG key'
        $tmpl = Get-Content (Join-Path $src '.chezmoi.toml.tmpl') -Raw
        if ($tmpl -notmatch 'recipient = "([^"]+)"') { throw '.chezmoi.toml.tmpl has no gpg recipient' }
        $recipient = $Matches[1]
        if ((Test-Quiet { gpg --list-secret-keys --keyid-format long $recipient }) -eq 0) {
            Write-Host "  [SKIP] key $recipient already imported" -ForegroundColor Yellow
        } else {
            $key = (Read-Host '  Path to the secret key backup (gpg-secret-<KEYID>.asc)').Trim('"', ' ')
            Invoke-Checked 'gpg --import' { gpg --import $key }
            $trust = (Read-Host '  Path to the ownertrust backup (Enter to skip)').Trim('"', ' ')
            if ($trust) { Invoke-Checked 'gpg --import-ownertrust' { gpg --import-ownertrust $trust } }
            Invoke-Checked "gpg key $recipient" { gpg --list-secret-keys --keyid-format long $recipient }
        }

        # -- 5. Seed the agent files before anything is decrypted ---------------
        Step 'GPG/SSH agent files'
        $gnupg = Join-Path $env:APPDATA 'gnupg'
        $ssh   = Join-Path $env:USERPROFILE '.ssh'
        New-Item -ItemType Directory -Force -Path $gnupg, $ssh | Out-Null
        Copy-Item "$src\private_dot_gnupg\gpg-agent.conf" "$gnupg\gpg-agent.conf" -Force
        Copy-Item "$src\private_dot_gnupg\private_sshcontrol" "$gnupg\sshcontrol" -Force
        Copy-Item "$src\dot_ssh\config" "$ssh\config" -Force
        Copy-Item "$src\dot_ssh\id_personal.pub" "$ssh\id_personal.pub" -Force
        Copy-Item "$src\dot_ssh\id_work.pub" "$ssh\id_work.pub" -Force
        Test-Quiet { gpgconf --kill gpg-agent } | Out-Null  # fails when no agent runs yet
        Invoke-Checked 'gpgconf --launch gpg-agent' { gpgconf --launch gpg-agent }

        # -- 6. Decryption check --------------------------------------------------
        Step 'Checking decryption (chezmoi diff)'
        chezmoi diff --no-pager --exclude=scripts > $null
        if ($LASTEXITCODE -ne 0) {
            throw 'chezmoi diff failed: GnuPG cannot decrypt yet (key imported? agent running?). Fix it and run again.'
        }
        Write-Host '  [OK] encrypted files decrypt' -ForegroundColor Green
    }

    # -- 7. Apply --------------------------------------------------------------
    Step 'chezmoi apply'
    if ($personal) {
        Invoke-Checked 'chezmoi apply' { chezmoi apply }
    } else {
        Invoke-Checked 'chezmoi apply' { chezmoi apply --exclude=encrypted }
    }

    Step 'Done'
    Write-Host '  Open a new terminal. For SSH through GPG run setup-gpg-ssh once.' -ForegroundColor Green
}
