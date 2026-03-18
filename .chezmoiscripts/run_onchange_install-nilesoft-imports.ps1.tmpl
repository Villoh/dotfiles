# run_onchange_ triggers when this script's content changes.
# Hashes are computed automatically for all .nss files in the source folder.
{{ range (glob "program_files/nilesoft/imports/*.nss") -}}
# {{ . }} {{ include . | sha256sum }}
{{ end }}
$src = "{{ .chezmoi.sourceDir }}/program_files/nilesoft/imports"
$dst = "C:\Program Files\Nilesoft Shell\imports"

$script = @"
Get-ChildItem '$src\*.nss' | ForEach-Object {
    Copy-Item `$_.FullName -Destination '$dst\`$(`$_.Name)' -Force
}
Write-Host 'Nilesoft Shell imports updated.'
"@

Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile", "-Command", $script -Wait
