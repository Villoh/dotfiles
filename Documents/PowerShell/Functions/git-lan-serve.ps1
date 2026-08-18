# ============================================================================
# git-lan-serve — PowerShell port of dot_local/bin/git-lan-serve.
# Windows equivalent of `git lan-serve <verb>`; call as a plain function since
# git doesn't chase .ps1 files for subcommand resolution.
# ============================================================================

function Get-GitLanAddr {
    (Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object { $_.IPAddress -notlike '127.*' -and $_.PrefixOrigin -ne 'WellKnown' } |
        Select-Object -First 1 -ExpandProperty IPAddress)
}

function Start-GitLanServe {
    param([string]$RemoteName)
    $root = git rev-parse --show-toplevel
    Push-Location $root
    $name = Split-Path -Leaf $root
    Pop-Location
    Push-Location (Split-Path $root -Parent)
    $repo = Join-Path (Get-Location) "$name.git"
    Write-Host $repo
    Remove-Item -Recurse -Force $repo -ErrorAction SilentlyContinue
    git clone --bare $root $repo
    $ip = Get-GitLanAddr
    Start-Process -NoNewWindow git -ArgumentList "daemon --verbose --export-all --enable=receive-pack --base-path=$(Get-Location) --reuseaddr --strict-paths `"$repo`""
    $remoteUrl = "git://${ip}:9418/$name.git"
    Write-Host "Serving repository from $remoteUrl"
    Pop-Location
    if ($RemoteName) { Set-GitRemote -Name $RemoteName -Url $remoteUrl }
}
Set-Alias -Name server-start -Value Start-GitLanServe

function Stop-GitLanServe {
    Get-Process git -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -match 'daemon' } |
        ForEach-Object { Write-Host "Killing: $($_.Id)"; Stop-Process -Id $_.Id -Force }
}
Set-Alias -Name server-kill -Value Stop-GitLanServe

function Test-GitLanServe {
    param([Parameter(Mandatory)][string]$RepoName)
    $remote = "git://$(Get-GitLanAddr):9418/$RepoName"
    git ls-remote $remote *>$null
    if ($LASTEXITCODE -eq 0) { Write-Host "Server running at: $remote"; return $true }
    return $false
}
Set-Alias -Name server-test -Value Test-GitLanServe

function Copy-GitLanServe {
    param([Parameter(Mandatory)][string]$RepoName)
    if (Test-GitLanServe -RepoName $RepoName) {
        git clone "git://$(Get-GitLanAddr):9418/$RepoName"
    }
}
Set-Alias -Name server-clone -Value Copy-GitLanServe

function Join-GitLanServe {
    $root = git rev-parse --show-toplevel
    $base = Split-Path -Leaf $root
    if (Test-GitLanServe -RepoName "$base.git") {
        Set-GitRemote -Name origin -Url "git://$(Get-GitLanAddr):9418/$base.git"
        Write-Host "origin updated: (fetch & push)"
    }
}
Set-Alias -Name server-join -Value Join-GitLanServe

function Get-GitLanServeLogs {
    Get-Content "$env:TEMP\git-daemon.log" -Wait -ErrorAction SilentlyContinue
}
Set-Alias -Name server-logs -Value Get-GitLanServeLogs
