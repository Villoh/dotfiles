package main

// The System step on NixOS: clone the user's own NixOS configuration where
// they want it, then nixos-rebuild test and switch it. That is what gives the
// machine Git, GnuPG and chezmoi (Home Manager), so it comes before Setup.
// Nothing here installs packages: the configuration does.

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/egoist/mygo/ui"
)

// Passed to nix and nixos-rebuild: a fresh NixOS may not have flakes enabled.
const nixFeatures = "nix-command flakes"

// nixosCfg is the NixOS configuration repository the user chose.
type nixosCfg struct{ url, dir, host string }

func (c nixosCfg) flake() string { return c.dir + "#" + c.host }

// clean checks the three fields and expands a leading ~/ in the directory.
func (c nixosCfg) clean() (nixosCfg, error) {
	c.url, c.dir, c.host = strings.TrimSpace(c.url), strings.TrimSpace(c.dir), strings.TrimSpace(c.host)
	if c.url == "" || c.dir == "" || c.host == "" {
		return c, errors.New("repository URL, directory and host are all required")
	}
	if rest, ok := strings.CutPrefix(c.dir, "~/"); ok {
		home, err := os.UserHomeDir()
		if err != nil {
			return c, err
		}
		c.dir = filepath.Join(home, rest)
	}
	return c, nil
}

// cloneCmd clones the configuration. A fresh NixOS may not have Git, so it is
// borrowed from nixpkgs for the clone.
func cloneCmd(hasGit bool, c nixosCfg) []string {
	args := []string{"git", "clone", "--recurse-submodules", c.url, c.dir}
	if hasGit {
		return args
	}
	return append([]string{"nix", "--extra-experimental-features", nixFeatures, "shell", "nixpkgs#git", "-c"}, args...)
}

// rebuildCmd runs nixos-rebuild as root through pkexec, the same way Setup
// elevates on other distributions. pkexec clears PATH, hence the full path.
// action is "test" (activates without touching the bootloader) or "switch".
func rebuildCmd(action string, c nixosCfg) []string {
	return []string{"pkexec", "/run/current-system/sw/bin/nixos-rebuild", action,
		"--flake", c.flake(), "--option", "experimental-features", nixFeatures}
}

// nixosRebuild clones the configuration if it is not there yet and runs
// nixos-rebuild action on it. A successful test is what unlocks switch.
func (a *app) nixosRebuild(action string, c nixosCfg) error {
	c, err := c.clean()
	if err != nil {
		return err
	}
	if _, err := os.Stat(filepath.Join(c.dir, "flake.nix")); err != nil {
		if entries, _ := os.ReadDir(c.dir); len(entries) > 0 {
			return fmt.Errorf("%s exists but has no flake.nix; choose another directory or clean it", c.dir)
		}
		cmd := cloneCmd(findExe("git") != "", c)
		if err := a.run(false, cmd[0], cmd[1:]...); err != nil {
			return err
		}
	} else {
		a.logf("Configuration already at %s", c.dir)
	}
	a.logf("Rebuilding; the system asks for your password.")
	cmd := rebuildCmd(action, c)
	if err := a.run(false, cmd[0], cmd[1:]...); err != nil {
		return err
	}
	a.checkDeps()
	a.post(func() {
		if action == "test" {
			a.nixosTested = c.flake()
			a.status, a.statusErr = "Test passed: the configuration is active until reboot. Switch makes it the boot default.", false
		} else {
			a.status, a.statusErr = "Switched. Continue with Setup.", false
		}
	})
	return nil
}

func (a *app) systemView(c *ui.Context) {
	a.card(c, func() {
		a.sectionTitle(c, "Your NixOS configuration")
		a.muted(c, "A flake repository with this machine's host already in it, including its hardware-configuration.nix.")
		a.textRow(c, "Repository URL", &a.nixos.url, "https://github.com/<you>/nixos-config")
		a.textRow(c, "Directory", &a.nixos.dir, "~/nixos-config")
		a.textRow(c, "Host", &a.nixos.host, "the nixosConfigurations name")
		ui.Row(c).Gap(8).Children(func() {
			cfg := a.nixos
			if a.button(c, filled, "Clone and test", a.busy != "") {
				a.step("Testing", func() error { return a.nixosRebuild("test", cfg) })
			}
			tested := a.nixosTested != "" && a.nixosTested == a.nixos.flake()
			if a.button(c, tonal, "Switch", a.busy != "" || !tested) {
				a.step("Switching", func() error { return a.nixosRebuild("switch", cfg) })
			}
		})
	})
	a.banner(c, info, "Test activates the configuration without touching the bootloader. Switch also makes it the boot default; with dual boot, read the bootloader notes in docs/install/nixos-dms.md first.")
}

func (a *app) textRow(c *ui.Context, label string, v *string, placeholder string) {
	// The field's own Label is not drawn, and a placeholder is gone once it is filled.
	ui.Column(c.Key(label)).Gap(4).Children(func() {
		ui.Text(c, label).FontSize(12).TextColor(a.scheme.OnSurfaceVariant)
		ui.TextInput(c, v).Placeholder(placeholder).Label(label).FillWidth().Height(40).Radius(8)
	})
}
