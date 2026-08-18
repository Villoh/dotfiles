# ============================================================================
# Git workflow helpers — PowerShell port of the bash dot_local/bin/git-* scripts.
# On Linux these are standalone `git-*` executables (invoked as `git <name>`).
# On Windows, git's own alias resolution doesn't chase down .ps1 files, so
# these are plain PowerShell functions instead — call them directly (not via
# `git <name>`) once this file is dot-sourced from your $PROFILE.
# ============================================================================

function Get-GitRemoteDefault {
    git rev-parse --abbrev-ref origin/HEAD *>$null
    if ($LASTEXITCODE -ne 0) { git remote set-head origin -a *>$null }
    (git rev-parse --abbrev-ref origin/HEAD) -replace '^origin/', ''
}
Set-Alias -Name remote-default -Value Get-GitRemoteDefault

function Set-GitRemote {
    param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][string]$Url)
    git remote get-url $Name *>$null
    if ($LASTEXITCODE -eq 0) { git remote set-url $Name $Url } else { git remote add $Name $Url }
}
Set-Alias -Name remote-set -Value Set-GitRemote

function Get-GitOldBranches {
    Write-Host "Fetching and Pruning..." -NoNewline
    git fetch --prune *>$null
    Write-Host "`r" -NoNewline
    $default = Get-GitRemoteDefault
    $current = git symbolic-ref --short HEAD
    $branches = git for-each-ref --sort=-committerdate --format='%(refname:short)|%(committerdate:relative)|%(upstream:track)' refs/heads/
    Write-Host '---------------------------- Branches ----------------------------'
    foreach ($line in $branches) {
        $branch, $date, $track = $line -split '\|'
        $ahead = (git rev-list --count "origin/$default..$branch" 2>$null)
        $behind = (git rev-list --count "$branch..origin/$default" 2>$null)
        $merged = if ($track -like '*gone*') { "MERGED by $(git log -1 --format='%cn' $branch)" } else { '' }
        $status = if ($branch -eq $current) { '*' } else { ' ' }
        '{0} {1,-30} | {2,-16} | +{3,-3} -{4,-3} | {5}' -f $status, $branch, $date, $ahead, $behind, $merged
    }
}
Set-Alias -Name old -Value Get-GitOldBranches

function Test-GitConflict {
    param([Parameter(Mandatory)][string]$Branch)
    $tmp = New-TemporaryFile
    $base = git merge-base HEAD $Branch
    git merge-tree $base HEAD $Branch | Out-File $tmp -Encoding utf8
    $content = Get-Content $tmp -Raw
    if ($content -match '<<<<<<<') {
        Get-Content $tmp | Select-String -Pattern '<<<<<<<|=======|>>>>>>>' -Context 0, 0
        Write-Host "❌ Merge conflict would occur!" -ForegroundColor Red
    } else {
        Write-Host '✅ No conflicts. Safe to merge.' -ForegroundColor Green
    }
    Remove-Item $tmp -Force
}
Set-Alias -Name conflict -Value Test-GitConflict
Set-Alias -Name cf -Value Test-GitConflict

function Test-GitCanMerge {
    param([Parameter(Mandatory)][string]$Branch)
    $tmp = New-TemporaryFile
    $base = git merge-base HEAD $Branch
    git merge-tree $base HEAD $Branch | Out-File $tmp -Encoding utf8
    $conflict = (Get-Content $tmp -Raw) -match '<<<<<<<'
    Remove-Item $tmp -Force
    if ($conflict) { Write-Host '❌ Merge conflict would occur!' -ForegroundColor Red; return $false }
    Write-Host '✅ No conflicts. Safe to merge.' -ForegroundColor Green
    return $true
}
Set-Alias -Name can-merge -Value Test-GitCanMerge
Set-Alias -Name cfm -Value Test-GitCanMerge

function Invoke-GitContinue {
    $gitdir = git rev-parse --git-dir
    if ((Test-Path "$gitdir/rebase-merge") -or (Test-Path "$gitdir/rebase-apply")) { git rebase --continue }
    elseif (Test-Path "$gitdir/MERGE_HEAD") { git merge --continue }
    elseif (Test-Path "$gitdir/CHERRY_PICK_HEAD") { git cherry-pick --continue }
    elseif (Test-Path "$gitdir/REVERT_HEAD") { git revert --continue }
    else { Write-Host '✅ Nothing to continue.' -ForegroundColor Green }
}
Set-Alias -Name continue-git -Value Invoke-GitContinue

function Invoke-GitAbort {
    $gitdir = git rev-parse --git-dir
    if ((Test-Path "$gitdir/rebase-merge") -or (Test-Path "$gitdir/rebase-apply")) {
        git rebase --abort
        Write-Host '✅ Aborted the rebase.' -ForegroundColor Green
    }
    elseif (Test-Path "$gitdir/MERGE_HEAD") { git merge --abort }
    elseif (Test-Path "$gitdir/CHERRY_PICK_HEAD") { git cherry-pick --abort }
    elseif ((git status --porcelain) -match '^(UU|AA|DD|UD|DU)') {
        $answer = Read-Host 'Unabortable conflicts detected. Reset changes? (Y/n)'
        if ($answer -match '^[Yy]$' -or [string]::IsNullOrEmpty($answer)) {
            git reset --hard
            git clean -fd
        } else {
            Write-Host '✅ Operation Canceled.' -ForegroundColor Green
        }
    }
    else { Write-Host '✅ Nothing to abort.' -ForegroundColor Green }
}
Set-Alias -Name abort-git -Value Invoke-GitAbort

function Remove-GitPruneLocal {
    git fetch -p
    (git branch -vv | Select-String ': gone]') | ForEach-Object {
        $branchName = ($_ -split '\s+')[1]
        git branch -d $branchName
    }
}
Set-Alias -Name prune-local -Value Remove-GitPruneLocal

function Remove-GitCleanMerged {
    (git branch --merged) | Where-Object { $_ -notmatch '\*|main|master|develop' } | ForEach-Object {
        git branch -d $_.Trim()
    }
}
Set-Alias -Name clean-merged -Value Remove-GitCleanMerged

function Invoke-GitAutoPrune {
    git diff --quiet
    $dirty1 = $LASTEXITCODE -ne 0
    git diff --cached --quiet
    $dirty2 = $LASTEXITCODE -ne 0
    if ($dirty1 -or $dirty2) { Write-Host '❌ Cannot safely switch branches' -ForegroundColor Red; return }
    $main = Get-GitRemoteDefault
    git switch $main *>$null
    git fetch --prune
    git pull
    $branches = git for-each-ref --format='%(refname:short)' refs/heads
    foreach ($branch in $branches) {
        if ($branch -in @('main', 'master', $main)) { continue }
        $base = git merge-base $main $branch
        $mergeDiff = git merge-tree $base $main $branch
        if ([string]::IsNullOrEmpty($mergeDiff)) { git branch -D $branch }
    }
}
Set-Alias -Name auto-prune -Value Invoke-GitAutoPrune

function Invoke-GitFixup {
    # NOTE: prefer `git absorb --and-rebase` (github.com/tummychow/git-absorb) if installed —
    # it finds the right target commit automatically instead of needing one passed in.
    param([Parameter(Mandatory)][string]$Commit)
    $target = git rev-parse $Commit
    git commit --fixup=$target
    if ($LASTEXITCODE -ne 0) { return }
    $commits = git rev-list --reverse "$target^..HEAD"
    foreach ($c in $commits) {
        $patch = git diff "$c^" $c
        $patch | git apply --check --3way -q
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Rebase conflict would occur!" -ForegroundColor Red
            git reset HEAD~1 --soft
            return
        }
    }
    git rebase -i --autosquash "$target^"
}
Set-Alias -Name fixup -Value Invoke-GitFixup

function Get-GitChurn {
    $lines = git -p log --all -M -C --name-only --format='format:'
    $lines | Where-Object { $_ -ne '' } | Group-Object | Sort-Object Count -Descending |
        Select-Object -First 25 | ForEach-Object { "{0} {1}" -f $_.Count, $_.Name }
}
Set-Alias -Name churn -Value Get-GitChurn

function Invoke-GitRebranch {
    $main = Get-GitRemoteDefault
    git savepoint
    if (-not (Test-GitCanMerge $main)) { return }
    $branch = git symbolic-ref --short HEAD
    git switch $main; if ($LASTEXITCODE -ne 0) { return }
    git pull; if ($LASTEXITCODE -ne 0) { return }
    git switch -
    $temp = [guid]::NewGuid().ToString()
    git switch -c $temp
    git switch $main
    git branch -D $branch
    git switch -c $branch
    $commits = git rev-list --reverse "$main..$temp"
    foreach ($c in $commits) {
        git cherry-pick $c
        if ($LASTEXITCODE -ne 0) { Write-Host "❌ cherry pick failed at $c" -ForegroundColor Red; return }
    }
    git branch -D $temp
}
Set-Alias -Name rebranch -Value Invoke-GitRebranch

function Invoke-GitYank {
    $branch = git rev-parse --abbrev-ref HEAD
    if ($branch -eq 'HEAD') { Write-Host 'Error: You are in a detached HEAD. Cannot yank.' -ForegroundColor Red; return }
    git rev-parse --abbrev-ref --symbolic-full-name "$branch@{u}" *>$null
    if ($LASTEXITCODE -ne 0) { Write-Host "Error: '$branch' has no upstream remote. Cannot yank." -ForegroundColor Red; return }
    git fetch origin $branch --force
    git savepoint
    $ahead = git rev-list --count "origin/$branch..$branch"
    if ($ahead -ne 0) {
        $backup = "$branch-old-$([guid]::NewGuid())"
        git branch $backup
        Write-Host "Created backup branch $backup"
    }
    git reset --hard "origin/$branch"
}
Set-Alias -Name yank -Value Invoke-GitYank

function Invoke-GitBackmerge {
    param([Parameter(Mandatory)][string]$Target)
    git switch $Target; if ($LASTEXITCODE -ne 0) { return }
    git pull; if ($LASTEXITCODE -ne 0) { return }
    git switch -
    git merge $Target
}
Set-Alias -Name backmerge -Value Invoke-GitBackmerge

function Get-GitLines {
    param([Parameter(Mandatory)][string]$Branch, [string[]]$Exclude)
    $excludes = @()
    foreach ($e in $Exclude) { $excludes += ":(exclude)$e" }
    git diff --shortstat "$Branch...HEAD" @excludes
}
Set-Alias -Name glines -Value Get-GitLines

function Get-GitSha {
    param([string]$Ref = 'HEAD')
    $sha = git rev-parse --short $Ref
    Write-Output $sha
    Set-Clipboard -Value $sha -ErrorAction SilentlyContinue
}
Set-Alias -Name sha -Value Get-GitSha

function Save-GitZip {
    $tag = git describe --tags --exact-match 2>$null
    if (-not $tag) { $tag = git tag --points-at HEAD | Select-Object -First 1 }
    git archive --format=zip -o "$tag.zip" HEAD
}
Set-Alias -Name gitzip -Value Save-GitZip

function Get-GitDiffFileLastCommit {
    param([Parameter(Mandatory)][string]$FileName)
    $root = git rev-parse --show-toplevel
    Write-Host "finding full file path of $FileName in $root"
    $filepath = Get-ChildItem -Path $root -Filter $FileName -Recurse -File | Select-Object -First 1 -ExpandProperty FullName
    Write-Host "full file path $filepath"
    $commit = git rev-list -1 HEAD -- $filepath
    Write-Host "last commit file modified $commit"
    git difftool "$commit^" -- $filepath
}
Set-Alias -Name diff-file-last-commit -Value Get-GitDiffFileLastCommit

function Add-GitExclude {
    param([Parameter(Mandatory)][string]$Path)
    $excludePath = git rev-parse --git-path info/exclude
    $existing = if (Test-Path $excludePath) { Get-Content $excludePath } else { @() }
    if ($existing -contains $Path) {
        Write-Host "⚠️  Already excluded: $Path" -ForegroundColor Yellow
    } else {
        Add-Content -Path $excludePath -Value $Path
        Write-Host "❎ Excluded: $Path" -ForegroundColor Green
    }
}
Set-Alias -Name gexclude -Value Add-GitExclude

function Remove-GitExclude {
    param([Parameter(Mandatory)][string]$Path)
    $excludePath = git rev-parse --git-path info/exclude
    $existing = if (Test-Path $excludePath) { Get-Content $excludePath } else { @() }
    if ($existing -contains $Path) {
        $existing | Where-Object { $_ -ne $Path } | Set-Content $excludePath
        Write-Host "❎ Removed: $Path" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Not found in exclude: $Path" -ForegroundColor Yellow
    }
}
Set-Alias -Name ginclude -Value Remove-GitExclude

function Show-GitTree {
    $seen = @{}
    $paths = @(git ls-files --cached --others --exclude-standard) | Sort-Object
    foreach ($p in $paths) {
        $parts = $p -split '/'
        $path = ''
        for ($i = 0; $i -lt $parts.Length - 1; $i++) {
            $path = if ($i -eq 0) { $parts[$i] } else { "$path/$($parts[$i])" }
            if (-not $seen.ContainsKey($path)) {
                $seen[$path] = $true
                $indent = ('│   ' * $i)
                Write-Host "$indent├── $($parts[$i])/" -ForegroundColor Blue
            }
        }
        $indent = ('│   ' * ($parts.Length - 1))
        Write-Host "$indent├── $($parts[-1])"
    }
}
Set-Alias -Name gtree -Value Show-GitTree
