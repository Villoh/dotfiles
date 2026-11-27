package main

// The System step on NixOS: clone the user's own NixOS configuration where
// they want it, then nixos-rebuild test and switch it. That is what gives the
// machine Git, GnuPG and chezmoi (Home Manager), so it comes before Setup.
// Nothing here installs packages: the configuration does.

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"slices"
	"strings"

	"github.com/egoist/mygo/ui"
)

// Passed to nix and nixos-rebuild: a fresh NixOS may not have flakes enabled.
const nixFeatures = "nix-command flakes"

// nixosCfg is the NixOS configuration repository the user chose.
type nixosCfg struct{ url, dir, host string }

func (c nixosCfg) flake() string { return c.dir + "#" + c.host }

// clean trims the fields, expands a leading ~/ in the directory and checks
// the directory is set. The URL is only needed to clone and the host is
// checked against the flake (checkHost), so neither is required here.
func (c nixosCfg) clean() (nixosCfg, error) {
	c.url, c.dir, c.host = strings.TrimSpace(c.url), strings.TrimSpace(c.dir), strings.TrimSpace(c.host)
	if c.dir == "" {
		return c, errors.New("directory is required")
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

// hostsCmd prints the flake's nixosConfigurations names as a JSON array.
func hostsCmd(dir string) []string {
	return []string{"nix", "--extra-experimental-features", nixFeatures, "eval", "--json",
		dir + "#nixosConfigurations", "--apply", "builtins.attrNames"}
}

// checkHost says which hosts the flake has when host is not one of them. The
// name is the flake's own, not the machine's hostname: they often differ.
func checkHost(hostsJSON, host string) error {
	var hosts []string
	if err := json.Unmarshal([]byte(hostsJSON), &hosts); err != nil {
		return fmt.Errorf("reading the flake's hosts: %w", err)
	}
	if len(hosts) == 0 {
		return errors.New("the flake has no nixosConfigurations")
	}
	if slices.Contains(hosts, host) {
		return nil
	}
	if host == "" {
		return fmt.Errorf("choose a host: %s", strings.Join(hosts, ", "))
	}
	return fmt.Errorf("host %q is not in the flake; choose one of: %s", host, strings.Join(hosts, ", "))
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
		if c.url == "" {
			return errors.New("repository URL is required to clone")
		}
		cmd := cloneCmd(findExe("git") != "", c)
		if err := a.run(false, cmd[0], cmd[1:]...); err != nil {
			return err
		}
	} else {
		a.logf("Configuration already at %s", c.dir)
	}
	cmd := hostsCmd(c.dir)
	hosts, err := a.output(cmd[0], cmd[1:]...)
	if err != nil {
		return fmt.Errorf("listing the flake's hosts: %w", err)
	}
	if err := checkHost(hosts, c.host); err != nil {
		return err
	}
	a.logf("Rebuilding; the system asks for your password.")
	cmd = rebuildCmd(action, c)
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
		a.muted(c, "A flake repository with this machine's host already in it, including its hardware-configuration.nix. Leave Host empty to list the flake's hosts after cloning.")
		a.textRow(c, "Repository URL", &a.nixos.url, "https://github.com/<you>/nixos-config")
		a.textRow(c, "Directory", &a.nixos.dir, "~/nixos-config")
		a.textRow(c, "Host", &a.nixos.host, "name in the flake's nixosConfigurations, not the hostname")
		ui.Row(c).Gap(8).Children(func() {
			cfg := a.nixos
			if a.button(c, filled, "Clone and test", a.busy != "") {
				a.step("Testing", func() error { return a.nixosRebuild("test", cfg) })
			}
			cleaned, _ := a.nixos.clean()
			tested := a.nixosTested != "" && a.nixosTested == cleaned.flake()
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
