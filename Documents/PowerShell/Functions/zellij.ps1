# =============================================================================
# Zellij helpers
# =============================================================================

# zj [query] — attach to existing session or create a new one
# If query is provided, uses zoxide to find the directory and names the
# session after it. If omitted, uses the current directory name.
function zj {
    param([string]$query)

    $name = if ($query) { $query } else { Split-Path $PWD -Leaf }

    $exists = zellij list-sessions 2>$null | Select-String -Pattern "^$name\b"

    if ($exists) {
        zellij attach $name
    } else {
        if ($query) {
            $dir = zoxide query $query 2>$null
            if (-not $dir) { Write-Error "zoxide: no match found for '$query'"; return }
            Set-Location $dir
        }
        zellij attach --create $name
    }
}

# zwork [query] — attach to or create the persistent "villoh" work session
# If query is provided, uses zoxide to navigate there first (only affects new sessions)
function zwork {
    param([string]$query)
    if ($query) {
        $dir = zoxide query $query 2>$null
        if (-not $dir) { Write-Error "zoxide: no match found for '$query'"; return }
        Set-Location $dir
    }
    zellij attach --create villoh
}
