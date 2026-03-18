# run_onchange_ triggers when this script's content changes.
# The hashes below are updated by chezmoi when source files change.
#
# develop.nss     {{ include "program_files/nilesoft/imports/develop.nss"     | sha256sum }}
# file-manage.nss {{ include "program_files/nilesoft/imports/file-manage.nss" | sha256sum }}
# goto.nss        {{ include "program_files/nilesoft/imports/goto.nss"        | sha256sum }}
# images.nss      {{ include "program_files/nilesoft/imports/images.nss"      | sha256sum }}
# modify.nss      {{ include "program_files/nilesoft/imports/modify.nss"      | sha256sum }}
# taskbar.nss     {{ include "program_files/nilesoft/imports/taskbar.nss"     | sha256sum }}
# terminal.nss    {{ include "program_files/nilesoft/imports/terminal.nss"    | sha256sum }}
# theme.nss       {{ include "program_files/nilesoft/imports/theme.nss"       | sha256sum }}

$src = "{{ .chezmoi.sourceDir }}/program_files/nilesoft/imports"
$dst = "C:\Program Files\Nilesoft Shell\imports"

$script = @"
Get-ChildItem '$src\*.nss' | ForEach-Object {
    Copy-Item `$_.FullName -Destination '$dst\`$(`$_.Name)' -Force
}
Write-Host 'Nilesoft Shell imports updated.'
"@

Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile", "-Command", $script -Wait
