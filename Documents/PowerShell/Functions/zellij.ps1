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
            $dir = zoxide query $query
            Set-Location $dir
        }
        zellij --session $name --layout work
    }
}

# zwork — attach to or create the persistent "villoh" work session
function zwork { zj villoh }
