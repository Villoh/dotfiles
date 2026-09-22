# Common post-install bootstrap

This is the handoff shared by every supported operating system. The OS-specific
install guide gets the machine to a working desktop; this guide restores the
personal environment through chezmoi.

## The important ordering rule

The encrypted Git configuration and other encrypted files cannot be applied
until the private GPG key for this repository is available to GnuPG.

Git and SSH do not need to be fully configured before applying a **public** copy
of this repository. Use HTTPS for the first bootstrap if necessary. SSH must be
ready before cloning through an SSH remote or using private Git repositories.
The encrypted Git configuration becomes the source of truth after chezmoi
applies it.

The secondary installation flow is intentionally different: when no private
GPG key is available, use `chezmoi init --apply --exclude=encrypted`. It skips
personal Git identities, work configuration, secrets, and other encrypted
files. The complete personal and secondary flows are documented in
[`INSTALL.md`](../../INSTALL.md).

## 1. Install the bootstrap tools

Install these using the operating-system guide:

- Git
- GnuPG (Gpg4win on Windows)
- OpenSSH
- chezmoi

On NixOS, Git, GnuPG, OpenSSH, and chezmoi belong in NixOS/Home Manager. On
Windows, install Git and chezmoi with winget and Gpg4win before applying the
dotfiles.

## 2. Import the private GPG material

Restore the private key and ownertrust from the secure backup made before
reinstalling the operating system:

```sh
gpg --import gpg-secret-<KEYID>.asc
gpg --import-ownertrust gpg-ownertrust.txt
gpg --list-secret-keys --keyid-format long
```

Confirm that the repository recipient key is available:

```sh
gpg --list-secret-keys --keyid-format long 2E5BD225E500AB50
```

Never put the exported key files inside this repository or commit them.

## 3. Initialize without applying

Use the public HTTPS URL for the first initialization when SSH is not ready:

```sh
chezmoi init https://github.com/Villoh/dotfiles
```

This clones the repository and creates the local chezmoi configuration without
writing the managed files yet. The source is now available through
`chezmoi source-path`.

## 4. Seed GPG and SSH from the repository

The agent configuration is intentionally plaintext and can be copied before
chezmoi applies the rest of the files. These source names map as follows:

| Chezmoi source | Physical destination |
| --- | --- |
| `private_dot_gnupg/gpg-agent.conf` | `~/.gnupg/gpg-agent.conf` |
| `private_dot_gnupg/private_sshcontrol` | `~/.gnupg/sshcontrol` |
| `dot_ssh/config` | `~/.ssh/config` |
| `dot_ssh/id_personal.pub` | `~/.ssh/id_personal.pub` |
| `dot_ssh/id_work.pub` | `~/.ssh/id_work.pub` |

Linux:

```sh
src="$(chezmoi source-path)"
mkdir -p "$HOME/.gnupg"
cp "$src/private_dot_gnupg/gpg-agent.conf" "$HOME/.gnupg/gpg-agent.conf"
cp "$src/private_dot_gnupg/private_sshcontrol" "$HOME/.gnupg/sshcontrol"
mkdir -p "$HOME/.ssh"
cp "$src/dot_ssh/config" "$HOME/.ssh/config"
cp "$src/dot_ssh/id_personal.pub" "$HOME/.ssh/id_personal.pub"
cp "$src/dot_ssh/id_work.pub" "$HOME/.ssh/id_work.pub"
chmod 700 "$HOME/.gnupg" "$HOME/.ssh"
chmod 600 "$HOME/.gnupg/gpg-agent.conf" "$HOME/.gnupg/sshcontrol" "$HOME/.ssh/config"
chmod 644 "$HOME/.ssh/id_personal.pub" "$HOME/.ssh/id_work.pub"
gpgconf --kill gpg-agent 2>/dev/null || true
gpgconf --launch gpg-agent
export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
```

Windows PowerShell:

```powershell
$src = chezmoi source-path
$gnupg = Join-Path $env:APPDATA "gnupg"
New-Item -ItemType Directory -Force -Path $gnupg | Out-Null
Copy-Item "$src\private_dot_gnupg\gpg-agent.conf" "$gnupg\gpg-agent.conf" -Force
Copy-Item "$src\private_dot_gnupg\private_sshcontrol" "$gnupg\sshcontrol" -Force
$ssh = Join-Path $env:USERPROFILE ".ssh"
New-Item -ItemType Directory -Force -Path $ssh | Out-Null
Copy-Item "$src\dot_ssh\config" "$ssh\config" -Force
Copy-Item "$src\dot_ssh\id_personal.pub" "$ssh\id_personal.pub" -Force
Copy-Item "$src\dot_ssh\id_work.pub" "$ssh\id_work.pub" -Force
gpgconf --kill gpg-agent 2>$null
gpgconf --launch gpg-agent
```

Now verify the intended authentication path when SSH uses a GPG authentication
subkey:

```sh
ssh-add -L
ssh -T github-personal
```

The repository contains only the SSH config and public key files. The private
authentication material stays in the GPG key and is served by `gpg-agent`.

On Windows, the post-apply `setup-gpg-ssh` helper creates the startup shortcut
so the copied agent configuration survives reboots.

Do not invent a second Git identity during bootstrap. The encrypted Git files
in this repository provide the identity, signing, and work-profile settings
once they can be decrypted.

## 5. Verify decryption, then apply

Run the checks before applying anything:

```sh
chezmoi status
chezmoi diff
```

A decryption error means that GnuPG, the private key, or the agent is not ready;
fix that first instead of excluding encrypted files. Once the diff is readable:

```sh
chezmoi apply
```

The apply now installs the platform Git configuration, GnuPG agent files, SSH
support files, and the rest of the dotfiles.

## 6. Validate the aligned environment

After applying, verify the three layers together:

```sh
gpg --list-secret-keys --keyid-format long
git config --show-origin --get user.name
git config --show-origin --get user.email
git config --show-origin --get user.signingkey
ssh-add -L
git ls-remote git@github.com:Villoh/dotfiles.git HEAD
```

On Windows, run `setup-gpg-ssh` once after the PowerShell functions are
available, then repeat the SSH check.

At this point the normal flow is available: use `chezmoi update` for dotfiles,
Git for repository changes, and the operating system's package manager for
system-owned packages.
