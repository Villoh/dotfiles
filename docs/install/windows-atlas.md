# Windows + AtlasOS installation

This guide gets a PC to a working Windows 11 with [Atlas](https://atlasos.net) applied. Then follow the
common [bootstrap guide](bootstrap.md), which restores everything else through chezmoi.

Atlas comes first and is not part of `chezmoi apply`: it needs a fresh Windows, updates Windows itself,
restarts the PC several times, and asks you to turn off four Windows Security switches by hand.

Everything here comes from Atlas's own documentation, read at 0.6.1; it has not been run from this repository.
The pinned Atlas Manager is 0.6.2, whose app was redesigned (Get ready runs by itself, one page of choices): the four
steps below still match it, but its screens and defaults may differ from this text. The
installer's Atlas page reads `%windir%\AtlasOS\state.json` (`installedVersion`) and `Install\active.json` (an
install in progress), as Atlas documents in `docs/install-state.md`; that reading has only been run against
sample files, not on a Windows with Atlas.

## Requirements

- Windows 11 **Pro, Education or Enterprise**, on a public 25H2 or 26H2 release. **Home, LTSC and Server are not
  supported**, and neither are Insider builds. Atlas does not activate Windows.
- A **fresh** install. On a PC that has been in use, Atlas warns that apps and settings may stop working, and it
  **removes OneDrive**, so files in it stop syncing. Back up first.
- A local account, or a Microsoft account that is an administrator. Not a work or school account, and not the
  built-in Administrator. Keep UAC on.
- No antivirus other than Microsoft Defender, an unmetered connection and the power cable on.
- Keep the network driver for the PC on separate storage, in case Windows cannot connect after the install.

## 1. Get Atlas Manager

The [installer GUI](../../INSTALL.md)'s first page, **Atlas**, does this: it downloads the pinned Manager, checks
its SHA-256 and opens it. By hand:

Check the file before running it. The version and SHA-256 below are the ones pinned in
`packages/windows/system/atlas.json`; change both together when you bump Atlas.

```powershell
$url  = "https://github.com/Atlas-OS/Atlas/releases/download/0.6.2/AtlasManager.exe"
$sha  = "26c1152dafaa5e500fbfc27f0e4305c4ad94c46ab0d847dfb6cb72b9fef35d81"
$exe  = "$env:USERPROFILE\Downloads\AtlasManager.exe"
Invoke-WebRequest $url -OutFile $exe
if ((Get-FileHash $exe -Algorithm SHA256).Hash -ne $sha.ToUpper()) { Remove-Item $exe; throw "SHA-256 mismatch" }
```

Once the dotfiles are applied, `install-atlas` does the same from `Documents/PowerShell/Functions/atlas.ps1` for
an update or a reinstall.

## 2. Install

**Recommended for a first install: an Atlas ISO.** In Atlas Manager choose **Create an Atlas ISO**, write it to a
USB drive (16 GB or more, it is erased), and install Windows from it. Atlas Manager opens after your first
sign-in and guides you through the rest.

**On a Windows you just installed from Microsoft's media:** run `AtlasManager.exe`, choose **Install Atlas** and
accept the UAC prompt. If it asks "Install Atlas on this PC?", Windows has been in use for a while: reinstall with
an ISO instead.

Atlas Manager runs four steps: **Get ready** (checks, Windows updates, restarts by itself), **Your choices**,
**Windows Security** and **Install**.

### Your choices

| Question | Suggestion |
| --- | --- |
| Keep Microsoft Defender? | **Keep** (recommended by Atlas). Removing it cannot be undone on that Windows installation. |
| Keep Windows' processor protections? | **Keep** (recommended by Atlas). |
| How should Windows install updates? | Your call: **Install updates myself** is Atlas's usual choice. |
| Multiple keyboard languages? | Answer for your keyboards; the keyboard here is US International. |
| Extras | Review **VBS** and **power saving** (both start ticked). Edge, a browser and Atlas Toolbox are optional: browsers come from winget later. |

### Windows Security

Turn off **Tamper Protection**, **Real-time protection**, **Cloud-delivered protection** and **Automatic sample
submission** for the install. Atlas Manager never changes them itself. This is separate from the Defender choice
above.

## 3. After Atlas

1. Install the bootstrap tools with winget, in an Administrator terminal:

   ```powershell
   winget install -e --id Git.Git
   winget install -e --id GnuPG.Gpg4win
   winget install -e --id twpayne.chezmoi --scope machine
   ```

2. Continue with the [common bootstrap](bootstrap.md) and [`INSTALL.md`](../../INSTALL.md): import the GPG key,
   `chezmoi init`, `chezmoi diff`, `chezmoi apply`. The Windows desktop is Aether, installed by
   `run_once_after_10_windows-aether`.
3. If a feature of the shell is missing (media controls, Wi-Fi, Bluetooth, volume, brightness), open Atlas Manager
   again, choose **Update to Atlas** and **Choose again**, and bring back only the setting you need. Which Atlas
   choices Aether depends on has not been checked yet.

## Updating or removing

- Update: `install-atlas`, then **Update to Atlas** and **Keep my choices**. Atlas 0.4.0 and older need a fresh
  Windows.
- There is no uninstaller: removing Atlas means reinstalling Windows.
