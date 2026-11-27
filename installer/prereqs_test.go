package main

import (
	"crypto/sha256"
	"encoding/hex"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestPlanPrereqs(t *testing.T) {
	fedora := osInfo{id: "fedora"}
	ubuntu := osInfo{id: "ubuntu", like: []string{"debian"}}
	cachy := osInfo{id: "cachyos", like: []string{"arch"}}
	bazzite := osInfo{id: "bazzite", like: []string{"fedora"}, ostree: true}
	nixos := osInfo{id: "nixos", nixos: true}
	gentoo := osInfo{id: "gentoo"}
	cmd := func(p prereqPlan) string { return strings.Join(p.cmd, " ") }

	for _, tc := range []struct {
		name    string
		o       osInfo
		missing []string
		goarch  string
		brew    bool
		chezmoi bool
		cmd     string
		manual  string // substring; "" means none
	}{
		{"nothing missing", fedora, nil, "amd64", false, false, "", ""},
		{"only chezmoi, no root", ubuntu, []string{"chezmoi"}, "amd64", false, true, "", ""},
		{"fedora gnupg2", fedora, []string{"git", "gpg", "chezmoi"}, "amd64", false, true, "pkexec dnf install -y git gnupg2", ""},
		{"ubuntu apt", ubuntu, []string{"git"}, "amd64", false, false, "pkexec sh -c apt-get update -q && apt-get install -y git", ""},
		{"arch-like pacman", cachy, []string{"gpg"}, "amd64", false, false, "pkexec pacman -S --needed --noconfirm gnupg", ""},
		{"atomic with brew, no root", bazzite, []string{"git", "chezmoi"}, "amd64", true, true, "brew install git", ""},
		{"atomic without brew", bazzite, []string{"gpg"}, "amd64", false, false, "", "rpm-ostree"},
		{"nixos installs nothing", nixos, []string{"git", "gpg", "chezmoi"}, "amd64", false, false, "", "home.packages = with pkgs; [ git gnupg chezmoi ]"},
		{"unknown distro", gentoo, []string{"git"}, "amd64", false, false, "", "with your package manager"},
		{"no static chezmoi on arm64", fedora, []string{"chezmoi"}, "arm64", false, false, "", "chezmoi.io/install"},
	} {
		p := planPrereqs(tc.o, tc.missing, tc.goarch, tc.brew, "pkexec")
		if p.chezmoi != tc.chezmoi || cmd(p) != tc.cmd {
			t.Errorf("%s: chezmoi %v cmd %q, want %v %q", tc.name, p.chezmoi, cmd(p), tc.chezmoi, tc.cmd)
		}
		if (tc.manual == "") != (p.manual == "") || !strings.Contains(p.manual, tc.manual) {
			t.Errorf("%s: manual %q, want %q", tc.name, p.manual, tc.manual)
		}
	}
}

// install.sh pins the same chezmoi build: bump both together.
func TestPinsMatch(t *testing.T) {
	b, err := os.ReadFile("../install.sh")
	if err != nil {
		t.Fatal(err)
	}
	for _, want := range []string{"chezmoi_url=" + chezmoiURL + "\n", "chezmoi_sha256=" + chezmoiSHA256 + "\n"} {
		if !strings.Contains(string(b), want) {
			t.Errorf("install.sh lacks %q", want)
		}
	}
}

func TestReadOSRelease(t *testing.T) {
	if got := (osInfo{id: "pop", like: []string{"ubuntu", "debian"}}).family(); got != "debian" {
		t.Errorf("pop family %q", got)
	}
	if got := (osInfo{id: "aurora", like: []string{"fedora"}}).family(); got != "fedora" {
		t.Errorf("aurora family %q", got)
	}
}

// The download lands in ~/.local/bin only with the right SHA-256.
func TestInstallChezmoi(t *testing.T) {
	body := []byte("#!/bin/sh\necho fake chezmoi\n")
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) { w.Write(body) }))
	defer srv.Close()
	t.Setenv("HOME", t.TempDir())
	t.Setenv("PATH", "/usr/bin")
	sum := sha256.Sum256(body)

	if _, err := installChezmoi(srv.URL, strings.Repeat("0", 64)); err == nil || !strings.Contains(err.Error(), "mismatch") {
		t.Fatalf("wrong checksum accepted: %v", err)
	}
	bin, _ := userBin()
	if entries, _ := os.ReadDir(bin); len(entries) != 0 {
		t.Errorf("a rejected download left files: %v", entries)
	}
	path, err := installChezmoi(srv.URL, hex.EncodeToString(sum[:]))
	if err != nil {
		t.Fatal(err)
	}
	if info, err := os.Stat(path); err != nil || info.Mode().Perm() != 0o755 || filepath.Dir(path) != bin {
		t.Errorf("installed %s: %v %v", path, info, err)
	}
	if !strings.HasPrefix(os.Getenv("PATH"), bin) {
		t.Errorf("PATH %s lacks %s", os.Getenv("PATH"), bin)
	}
}
