package main

// How the installer gets Git, GnuPG and chezmoi on Linux. Windows installs
// them with winget (run.go). On Linux:
//   - chezmoi, the one usually missing: chezmoi's own static binary into
//     ~/.local/bin, without root, at a pinned version checked by SHA-256.
//   - git and gpg, which most desktops ship: the distribution's package
//     manager, elevated (pkexec in the GUI), on mutable distributions; brew on
//     atomic ones (Bazzite, Fedora Atomic), whose image rpm-ostree changes.
//   - NixOS installs nothing: the configuration is declarative, so the
//     installer shows what to add to Home Manager.

import (
	"bufio"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"slices"
	"strings"
)

// chezmoi's static Linux build (musl), pinned. Bump both together, from
// https://github.com/twpayne/chezmoi/releases (chezmoi_<v>_checksums.txt).
const (
	chezmoiURL    = "https://github.com/twpayne/chezmoi/releases/download/v2.74.2/chezmoi-linux-amd64-musl"
	chezmoiSHA256 = "cebbe027a4c9b420a9aa3e55356c4d084f6d4a2c5562d18922494316f5656e0e"
)

// osInfo is what decides how to install on Linux.
type osInfo struct {
	id     string   // os-release ID, e.g. fedora
	like   []string // os-release ID_LIKE
	nixos  bool     // /etc/NIXOS
	ostree bool     // /run/ostree-booted: an atomic image (Bazzite, Silverblue)
}

func readOS() osInfo {
	o := osInfo{}
	_, err := os.Stat("/etc/NIXOS")
	o.nixos = err == nil
	_, err = os.Stat("/run/ostree-booted")
	o.ostree = err == nil
	f, err := os.Open("/etc/os-release")
	if err != nil {
		return o
	}
	defer f.Close()
	for s := bufio.NewScanner(f); s.Scan(); {
		k, v, ok := strings.Cut(s.Text(), "=")
		if !ok {
			continue
		}
		v = strings.Trim(v, `"'`)
		switch k {
		case "ID":
			o.id = v
		case "ID_LIKE":
			o.like = strings.Fields(v)
		}
	}
	return o
}

// family is the package manager's family: debian, fedora, arch, or "".
func (o osInfo) family() string {
	ids := append([]string{o.id}, o.like...)
	for _, f := range []struct {
		name string
		ids  []string
	}{
		{"debian", []string{"debian", "ubuntu"}},
		{"fedora", []string{"fedora", "rhel", "centos"}},
		{"arch", []string{"arch"}},
	} {
		for _, id := range ids {
			if slices.Contains(f.ids, id) {
				return f.name
			}
		}
	}
	return ""
}

// prereqPlan is how to get the missing tools.
type prereqPlan struct {
	chezmoi bool     // download chezmoi into ~/.local/bin
	cmd     []string // installs git and/or gnupg; nil when none is needed or possible
	manual  string   // what the user has to do instead; "" when nothing is left
}

// planPrereqs decides how to get missing ("git", "gpg", "chezmoi") on o.
// elevate runs the package manager as root: pkexec in the GUI, sudo in a
// terminal.
func planPrereqs(o osInfo, missing []string, goarch string, hasBrew bool, elevate string) prereqPlan {
	var p prereqPlan
	if len(missing) == 0 {
		return p
	}
	if o.nixos {
		pkgs := strings.Join(nixNames(missing), " ")
		p.manual = "Add them to your NixOS or Home Manager configuration and rebuild:\n  home.packages = with pkgs; [ " + pkgs + " ];"
		return p
	}
	var sys []string // git and gpg: the system's packages
	for _, m := range missing {
		if m == "chezmoi" {
			p.chezmoi = goarch == "amd64"
		} else {
			sys = append(sys, m)
		}
	}
	var manual []string
	if slices.Contains(missing, "chezmoi") && !p.chezmoi {
		manual = append(manual, "chezmoi has no static build for "+goarch+": install it from https://www.chezmoi.io/install/")
	}
	if len(sys) > 0 {
		switch fam := o.family(); {
		case o.ostree && hasBrew:
			p.cmd = append([]string{"brew", "install"}, pkgNames("brew", sys)...)
		case o.ostree:
			manual = append(manual, "This system's image is read-only: install Homebrew and run brew install "+
				strings.Join(pkgNames("brew", sys), " ")+", or layer them with rpm-ostree install and reboot.")
		case fam == "debian":
			p.cmd = []string{elevate, "sh", "-c", "apt-get update -q && apt-get install -y " + strings.Join(pkgNames(fam, sys), " ")}
		case fam == "fedora":
			p.cmd = append([]string{elevate, "dnf", "install", "-y"}, pkgNames(fam, sys)...)
		case fam == "arch":
			p.cmd = append([]string{elevate, "pacman", "-S", "--needed", "--noconfirm"}, pkgNames(fam, sys)...)
		default:
			manual = append(manual, "Install "+strings.Join(pkgNames("", sys), " and ")+" with your package manager.")
		}
	}
	p.manual = strings.Join(manual, "\n")
	return p
}

// pkgNames maps the tools to the packages of a family.
func pkgNames(family string, tools []string) []string {
	var out []string
	for _, t := range tools {
		switch {
		case t == "gpg" && family == "fedora":
			out = append(out, "gnupg2")
		case t == "gpg":
			out = append(out, "gnupg")
		default:
			out = append(out, t)
		}
	}
	return out
}

func nixNames(tools []string) []string { return pkgNames("", tools) }

// userBin is ~/.local/bin, where chezmoi goes without root.
func userBin() (string, error) {
	home, err := os.UserHomeDir()
	return filepath.Join(home, ".local", "bin"), err
}

// installChezmoi downloads the pinned chezmoi into ~/.local/bin, checks it,
// and puts the directory on this process's PATH.
func installChezmoi(url, sum string) (string, error) {
	dir, err := userBin()
	if err != nil {
		return "", err
	}
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return "", err
	}
	resp, err := http.Get(url)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("downloading chezmoi: %s", resp.Status)
	}
	tmp, err := os.CreateTemp(dir, ".chezmoi-*")
	if err != nil {
		return "", err
	}
	defer os.Remove(tmp.Name()) // a no-op once renamed
	h := sha256.New()
	if _, err := io.Copy(io.MultiWriter(tmp, h), resp.Body); err != nil {
		tmp.Close()
		return "", err
	}
	if err := tmp.Close(); err != nil {
		return "", err
	}
	if got := hex.EncodeToString(h.Sum(nil)); got != sum {
		return "", fmt.Errorf("chezmoi SHA-256 mismatch: got %s, want %s", got, sum)
	}
	if err := os.Chmod(tmp.Name(), 0o755); err != nil {
		return "", err
	}
	path := filepath.Join(dir, "chezmoi")
	if err := os.Rename(tmp.Name(), path); err != nil {
		return "", err
	}
	addToPath(dir)
	return path, nil
}

func addToPath(dir string) {
	if !slices.Contains(filepath.SplitList(os.Getenv("PATH")), dir) {
		os.Setenv("PATH", dir+string(os.PathListSeparator)+os.Getenv("PATH"))
	}
}
