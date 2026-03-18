# run_onchange_ triggers when this script's content changes.
# The hashes below are updated by chezmoi when source files change.
#
# Classic.xml               {{ include "program_files/ditto/Themes/Classic.xml"               | sha256sum }}
# DarkerDitto.xml           {{ include "program_files/ditto/Themes/DarkerDitto.xml"           | sha256sum }}
# MonoDark.xml              {{ include "program_files/ditto/Themes/MonoDark.xml"              | sha256sum }}
# Monolight.xml             {{ include "program_files/ditto/Themes/Monolight.xml"             | sha256sum }}
# Nord.xml                  {{ include "program_files/ditto/Themes/Nord.xml"                  | sha256sum }}
# Selenized Black.xml       {{ include "program_files/ditto/Themes/Selenized Black.xml"       | sha256sum }}
# Selenized Dark.xml        {{ include "program_files/ditto/Themes/Selenized Dark.xml"        | sha256sum }}
# Selenized Light.xml       {{ include "program_files/ditto/Themes/Selenized Light.xml"       | sha256sum }}
# Selenized Strong.xml      {{ include "program_files/ditto/Themes/Selenized Strong.xml"      | sha256sum }}
# Selenized White.xml       {{ include "program_files/ditto/Themes/Selenized White.xml"       | sha256sum }}
# Selenized-Dark.xml        {{ include "program_files/ditto/Themes/Selenized-Dark.xml"        | sha256sum }}
# Terminal.xml              {{ include "program_files/ditto/Themes/Terminal.xml"              | sha256sum }}
# catppuccin-mocha-mauve.xml {{ include "program_files/ditto/Themes/catppuccin-mocha-mauve.xml" | sha256sum }}

$src = "{{ .chezmoi.sourceDir }}/program_files/ditto/Themes"
$dst = "C:\Program Files\Ditto\Themes"

$script = @"
Get-ChildItem '$src\*.xml' | ForEach-Object {
    Copy-Item `$_.FullName -Destination '$dst\`$(`$_.Name)' -Force
}
Write-Host 'Ditto themes updated.'
"@

Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile", "-Command", $script -Wait
