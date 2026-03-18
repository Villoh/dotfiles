# run_onchange_ triggers when this script's content changes.
# Hashes are computed automatically for all .xml files in the source folder.
{{ range (glob "program_files/ditto/Themes/*.xml") -}}
# {{ . }} {{ include . | sha256sum }}
{{ end }}
$src = "{{ .chezmoi.sourceDir }}/program_files/ditto/Themes"
$dst = "C:\Program Files\Ditto\Themes"

$script = @"
Get-ChildItem '$src\*.xml' | ForEach-Object {
    Copy-Item `$_.FullName -Destination '$dst\`$(`$_.Name)' -Force
}
Write-Host 'Ditto themes updated.'
"@

Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile", "-Command", $script -Wait
