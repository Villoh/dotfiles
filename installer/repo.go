package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"slices"
	"strings"
)

// repoInfo is what the installer reads from the cloned dotfiles repository, so
// the GUI follows .chezmoi.toml.tmpl and packages/windows instead of copies.
type repoInfo struct {
	ProfilePrompt string   // promptChoiceOnce text of install_profile
	SecretsPrompt string   // promptBool text of enable_secrets
	ModuleFormat  string   // printf format of the per-module promptBool, e.g. "Enable %s"
	Modules       []string // modules that exist on this OS ($common and $windowsOnly or $linuxOnly)
	MinimalOff    []string // modules the minimal profile turns off
	Recipient     string   // GPG recipient of the encrypted files

	Winget   map[string][]string // "minimal"/"full" -> winget package IDs
	Scoop    map[string][]string // "minimal"/"full" -> scoop app names
	Elevated []string            // winget IDs installed elevated
}

var (
	listRe      = regexp.MustCompile(`\$(\w+) := list ((?:"[^"]*"\s*)+)`)
	quotedRe    = regexp.MustCompile(`"([^"]*)"`)
	profileRe   = regexp.MustCompile(`promptChoiceOnce \. "install_profile" "([^"]+)"`)
	secretsRe   = regexp.MustCompile(`promptBool "([^"]*secrets[^"]*)"`)
	moduleRe    = regexp.MustCompile(`promptBool \(printf "([^"]*%s[^"]*)" \.\)`)
	recipientRe = regexp.MustCompile(`recipient = "([^"]+)"`)
)

// parseConfigTemplate extracts prompts and the modules of goos from
// .chezmoi.toml.tmpl.
func parseConfigTemplate(src, goos string) (repoInfo, error) {
	var r repoInfo
	lists := map[string][]string{}
	for _, m := range listRe.FindAllStringSubmatch(src, -1) {
		for _, q := range quotedRe.FindAllStringSubmatch(m[2], -1) {
			lists[m[1]] = append(lists[m[1]], q[1])
		}
	}
	one := func(re *regexp.Regexp, what string) (string, error) {
		m := re.FindStringSubmatch(src)
		if m == nil {
			return "", fmt.Errorf(".chezmoi.toml.tmpl: %s not found", what)
		}
		return m[1], nil
	}
	var err error
	if r.ProfilePrompt, err = one(profileRe, "install_profile prompt"); err != nil {
		return r, err
	}
	if r.SecretsPrompt, err = one(secretsRe, "secrets prompt"); err != nil {
		return r, err
	}
	if r.ModuleFormat, err = one(moduleRe, "module prompt"); err != nil {
		return r, err
	}
	if r.Recipient, err = one(recipientRe, "gpg recipient"); err != nil {
		return r, err
	}
	osList := map[string]string{"windows": "windowsOnly", "linux": "linuxOnly"}[goos]
	if osList == "" {
		return r, fmt.Errorf("no modules for %s: the installer supports Windows and Linux", goos)
	}
	if len(lists["common"]) == 0 || len(lists[osList]) == 0 {
		return r, fmt.Errorf(".chezmoi.toml.tmpl: $common/$%s module lists not found", osList)
	}
	r.Modules = append(slices.Clone(lists["common"]), lists[osList]...)
	for _, m := range lists["minimalOff"] {
		if slices.Contains(r.Modules, m) {
			r.MinimalOff = append(r.MinimalOff, m)
		}
	}
	return r, nil
}

// loadRepo reads everything the GUI needs on goos from the source directory.
// Package lists exist on Windows only: NixOS installs Linux's packages.
func loadRepo(src, goos string) (repoInfo, error) {
	b, err := os.ReadFile(filepath.Join(src, ".chezmoi.toml.tmpl"))
	if err != nil {
		return repoInfo{}, err
	}
	r, err := parseConfigTemplate(string(b), goos)
	if err != nil {
		return r, err
	}
	r.Winget, r.Scoop = map[string][]string{}, map[string][]string{}
	if goos != "windows" {
		return r, nil
	}
	pkg := filepath.Join(src, "packages", "windows")
	for _, v := range []string{"minimal", "full"} {
		file := map[string]string{"minimal": "minimal.json", "full": "packages.json"}[v]
		if r.Winget[v], err = wingetIDs(filepath.Join(pkg, "winget", file)); err != nil {
			return r, err
		}
		if r.Scoop[v], err = scoopApps(filepath.Join(pkg, "scoop", file)); err != nil {
			return r, err
		}
	}
	r.Elevated, err = wingetIDs(filepath.Join(pkg, "winget", "elevated.json"))
	return r, err
}

// wingetIDs reads a `winget export` file; a missing file is an empty list,
// as in run_once_00_windows-install.
func wingetIDs(path string) ([]string, error) {
	var f struct {
		Sources []struct {
			Packages []struct{ PackageIdentifier string }
		}
	}
	if err := readJSON(path, &f); err != nil {
		return nil, err
	}
	var ids []string
	for _, s := range f.Sources {
		for _, p := range s.Packages {
			ids = append(ids, p.PackageIdentifier)
		}
	}
	slices.Sort(ids)
	return ids, nil
}

func scoopApps(path string) ([]string, error) {
	var f struct{ Apps []struct{ Name string } }
	if err := readJSON(path, &f); err != nil {
		return nil, err
	}
	var names []string
	for _, a := range f.Apps {
		names = append(names, a.Name)
	}
	slices.Sort(names)
	return names, nil
}

func readJSON(path string, v any) error {
	b, err := os.ReadFile(path)
	if os.IsNotExist(err) {
		return nil
	}
	if err != nil {
		return err
	}
	// winget and scoop exports from PowerShell 5.1 can start with a BOM.
	b = []byte(strings.TrimPrefix(string(b), "\ufeff"))
	if err := json.Unmarshal(b, v); err != nil {
		return fmt.Errorf("%s: %w", path, err)
	}
	return nil
}
