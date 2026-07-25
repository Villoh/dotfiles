function Install-PnpmGlobalNow {
    param(
        [Parameter(Mandatory, Position = 0, ValueFromRemainingArguments)]
        [string[]] $Package
    )

    pnpm --config.minimum-release-age=0 add -g @Package
}
Set-Alias -Name pnpm-add-fresh -Value Install-PnpmGlobalNow
