function Get-AgentSkills {
    param(
        [ValidateSet('Enabled', 'Disabled', 'All')]
        [string]$State = 'All'
    )

    $roots = @(
        @{ State = 'Enabled'; Path = Join-Path $HOME '.agents/skills' }
        @{ State = 'Disabled'; Path = Join-Path $HOME '.agents/skills.disabled' }
    )

    foreach ($root in $roots) {
        if ($State -ne 'All' -and $State -ne $root.State) { continue }
        if (-not (Test-Path -LiteralPath $root.Path -PathType Container)) { continue }

        Get-ChildItem -LiteralPath $root.Path -Directory | Where-Object {
            Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') -PathType Leaf
        } | Sort-Object Name | ForEach-Object {
            [PSCustomObject]@{
                State = $root.State
                Name  = $_.Name
                Path  = $_.FullName
            }
        }
    }
}

function Show-AgentSkills {
    param(
        [ValidateSet('Enabled', 'Disabled', 'All')]
        [string]$State = 'All'
    )

    $skills = @(Get-AgentSkills -State $State)
    if ($skills.Count -eq 0) {
        Write-Host "No $State shared agent skills found." -ForegroundColor Yellow
        return
    }

    $skills | Format-Table State, Name -AutoSize
}

function Set-AgentSkillState {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Enabled', 'Disabled')]
        [string]$State,
        [string[]]$Name
    )

    $sourceState = if ($State -eq 'Disabled') { 'Enabled' } else { 'Disabled' }
    $available = @(Get-AgentSkills -State $sourceState)
    if ($available.Count -eq 0) {
        Write-Host "No $sourceState skills found." -ForegroundColor Yellow
        return
    }

    if (-not $Name) {
        $available | Select-Object @{ Name = '#'; Expression = { [array]::IndexOf($available, $_) + 1 } }, Name | Format-Table -AutoSize
        $Name = (Read-Host "Enter $sourceState skill names, separated by commas").Split(',').Trim() | Where-Object { $_ }
        if (-not $Name) { return }
    }

    $selected = @($available | Where-Object Name -In $Name)
    $missing = @($Name | Where-Object { $_ -notin $selected.Name })
    if ($missing) { throw "Unknown $sourceState skill: $($missing -join ', ')" }

    $destinationRoot = if ($State -eq 'Enabled') {
        Join-Path $HOME '.agents/skills'
    }
    else {
        Join-Path $HOME '.agents/skills.disabled'
    }
    foreach ($skill in $selected) {
        $destination = Join-Path $destinationRoot $skill.Name
        if (Test-Path -LiteralPath $destination) {
            Write-Warning "$($skill.Name) already exists in $State skills."
            continue
        }

        if ($PSCmdlet.ShouldProcess($skill.Name, "move to $State skills")) {
            New-Item -ItemType Directory -Path $destinationRoot -Force | Out-Null
            Move-Item -LiteralPath $skill.Path -Destination $destination
        }
    }
}

function Disable-AgentSkill {
    param([string[]]$Name)
    Set-AgentSkillState -State Disabled -Name $Name
}

function Enable-AgentSkill {
    param([string[]]$Name)
    Set-AgentSkillState -State Enabled -Name $Name
}

function Invoke-AgentSkillsTui {
    $cursorVisible = $null
    try {
        try {
            $cursorVisible = [Console]::CursorVisible
            [Console]::CursorVisible = $false
        }
        catch { Write-Verbose 'Console cursor visibility is unavailable in this host.' }

        $selection = 0
        $query = ''
        $message = $null

        while ($true) {
            $allSkills = @(Get-AgentSkills)
            if ($allSkills.Count -eq 0) {
                Clear-Host
                Write-Host 'No shared agent skills found.' -ForegroundColor Yellow
                return
            }

            $skills = @($allSkills | Where-Object Name -Like "*$query*")
            if ($skills.Count -gt 0) { $selection = [Math]::Min($selection, $skills.Count - 1) }
            else { $selection = 0 }
            $pageSize = [Math]::Max(3, $Host.UI.RawUI.WindowSize.Height - 7)
            $page = [Math]::Floor($selection / $pageSize)
            $start = $page * $pageSize
            $end = [Math]::Min($start + $pageSize, $skills.Count)

            Clear-Host
            $totalPages = [Math]::Max(1, [Math]::Ceiling($skills.Count / $pageSize))
            Write-Host 'Agent skills' -ForegroundColor Cyan
            Write-Host 'Type to search  Backspace: erase  Enter/Space: toggle  Esc: clear/quit' -ForegroundColor DarkGray
            Write-Host "Search: $query  $message" -ForegroundColor Yellow
            Write-Host ''

            if ($skills.Count -eq 0) { Write-Host 'No skills match the search.' -ForegroundColor Yellow }
            for ($index = $start; $index -lt $end; $index++) {
                $skill = $skills[$index]
                $cursor = if ($index -eq $selection) { '>' } else { ' ' }
                $color = if ($skill.State -eq 'Enabled') { 'Green' } else { 'DarkGray' }
                Write-Host "$cursor [$($skill.State[0])] $($skill.Name)" -ForegroundColor $color
            }

            Write-Host ''
            Write-Host "Page $($page + 1)/$totalPages  Up/Down: move  PgUp/PgDn: page" -ForegroundColor DarkGray
            $key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            $message = $null
            switch ($key.VirtualKeyCode) {
                38 { if ($skills.Count) { $selection = [Math]::Max(0, $selection - 1) } }
                40 { if ($skills.Count) { $selection = [Math]::Min($skills.Count - 1, $selection + 1) } }
                33 { if ($skills.Count) { $selection = [Math]::Max(0, $selection - $pageSize) } }
                34 { if ($skills.Count) { $selection = [Math]::Min($skills.Count - 1, $selection + $pageSize) } }
                { $_ -in 13, 32 } {
                    if ($skills.Count) {
                        $skill = $skills[$selection]
                        $state = if ($skill.State -eq 'Enabled') { 'Disabled' } else { 'Enabled' }
                        Set-AgentSkillState -State $state -Name $skill.Name
                        $updated = @(Get-AgentSkills)
                        $selection = [Math]::Max(0, [array]::IndexOf([string[]]$updated.Name, $skill.Name))
                        $message = "$($skill.Name) is now $state."
                    }
                }
                27 {
                    if ($query) {
                        $query = ''
                        $selection = 0
                    }
                    else { Clear-Host; return }
                }
                8 {
                    if ($query) { $query = $query.Substring(0, $query.Length - 1) }
                    $selection = 0
                }
                default {
                    if (-not [char]::IsControl([char]$key.Character)) {
                        $query += $key.Character
                        $selection = 0
                    }
                }
            }
        }
    }
    finally {
        if ($null -ne $cursorVisible) {
            try { [Console]::CursorVisible = $cursorVisible }
            catch { Write-Verbose 'Console cursor visibility is unavailable in this host.' }
        }
    }
}

function Invoke-AgentSkills {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [ValidateSet('tui', 'list')]
        [string]$Command = 'tui',
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Option
    )

    if ($Command -eq 'tui') {
        if ($Option) { throw 'The TUI does not accept options.' }
        Invoke-AgentSkillsTui
        return
    }

    $state = switch ($Option) {
        '--enabled' { 'Enabled'; break }
        '--disabled' { 'Disabled'; break }
        $null { 'All'; break }
        default { throw 'Usage: agent-skills list [--enabled|--disabled]' }
    }
    Show-AgentSkills -State $state
}

Set-Alias -Name agent-skills -Value Invoke-AgentSkills





