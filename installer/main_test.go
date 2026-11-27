package main

import (
	"errors"
	"fmt"
	"image/png"
	"os"
	"os/exec"
	"path/filepath"
	"slices"
	"strings"
	"testing"

	"github.com/egoist/mygo/ui"
)

// The GUI reads the real repository, so this fails when .chezmoi.toml.tmpl
// or packages/windows change shape.
func TestLoadRepo(t *testing.T) {
	r, err := loadRepo("..")
	if err != nil {
		t.Fatal(err)
	}
	if r.ProfilePrompt != "Install profile" || r.ModuleFormat != "Enable %s" || r.Recipient == "" {
		t.Errorf("prompts %q %q, recipient %q", r.ProfilePrompt, r.ModuleFormat, r.Recipient)
	}
	if !strings.Contains(r.SecretsPrompt, "secrets") {
		t.Errorf("secrets prompt %q", r.SecretsPrompt)
	}
	for _, m := range []string{"zed", "aether", "startup"} {
		if !slices.Contains(r.Modules, m) {
			t.Errorf("module %s missing from %v", m, r.Modules)
		}
	}
	if slices.Contains(r.Modules, "dms") || !slices.Contains(r.MinimalOff, "aether") {
		t.Errorf("modules %v, minimal off %v", r.Modules, r.MinimalOff)
	}
	if len(r.Winget["full"]) == 0 || len(r.Winget["minimal"]) == 0 || len(r.Scoop["full"]) == 0 || len(r.Elevated) == 0 {
		t.Errorf("package lists: winget %d/%d scoop %d elevated %d",
			len(r.Winget["minimal"]), len(r.Winget["full"]), len(r.Scoop["full"]), len(r.Elevated))
	}
}

func TestInitArgs(t *testing.T) {
	r := repoInfo{ProfilePrompt: "Install profile", SecretsPrompt: "Enable secrets", ModuleFormat: "Enable %s", Modules: []string{"zed", "warp"}}
	got := strings.Join(initArgs(r, "custom", false, map[string]bool{"zed": true}), "|")
	want := "init|--no-tty|--promptChoice|Install profile=custom|--promptBool|Enable secrets=false|--promptBool|Enable zed=true|--promptBool|Enable warp=false"
	if got != want {
		t.Errorf("got  %s\nwant %s", got, want)
	}
	if got := initArgs(r, "full", true, nil); len(got) != 6 {
		t.Errorf("full profile asks no modules: %q", got)
	}
}

// Runs the console script with a fake chezmoi: the exit code must come back
// and the prompt must not print an error. Skipped without pwsh (CI has it).
func TestApplyScript(t *testing.T) {
	pwsh, err := exec.LookPath("pwsh")
	if err != nil {
		t.Skip("pwsh not installed")
	}
	fake := filepath.Join(t.TempDir(), "chezmoi's.ps1") // a quote, to test the escaping
	if err := os.WriteFile(fake, []byte("if ($args -notcontains '--exclude=encrypted') { exit 9 }; exit 3"), 0o644); err != nil {
		t.Fatal(err)
	}
	cmd := exec.Command(pwsh, "-NoProfile", "-Command", applyScript(fake, false))
	cmd.Stdin = strings.NewReader("\n")
	out, err := cmd.CombinedOutput()
	var exit *exec.ExitError
	if !errors.As(err, &exit) || exit.ExitCode() != 3 {
		t.Fatalf("want exit 3, got %v\n%s", err, out)
	}
	if !strings.Contains(string(out), "chezmoi apply failed (exit 3)") || strings.Contains(string(out), "Exception") {
		t.Errorf("output:\n%s", out)
	}
}

func TestLineWriter(t *testing.T) {
	var lines []string
	w := &lineWriter{log: func(s string) { lines = append(lines, s) }}
	w.Write([]byte("a\r\n  -  \rb"))
	w.Write([]byte("c\nd"))
	w.Write([]byte("\n\x1b[32m[OK]\x1b[0m Scoop\x1b[?25l\n"))
	w.Flush()
	if strings.Join(lines, ",") != "a,-,bc,d,[OK] Scoop" {
		t.Errorf("lines %q", lines)
	}
}

func TestApplyArgs(t *testing.T) {
	if got := strings.Join(applyArgs(false), " "); got != "apply --no-tty --exclude=encrypted" {
		t.Errorf("secondary: %s", got)
	}
	if got := strings.Join(applyArgs(true), " "); got != "apply --no-tty" {
		t.Errorf("personal: %s", got)
	}
}

func TestPackagesView(t *testing.T) {
	a := newApp()
	a.setRepo(repoInfo{
		Modules: []string{"zed"},
		Winget:  map[string][]string{"full": {"Git.Git", "Spotify.Spotify"}, "minimal": {"Git.Git"}},
		Scoop:   map[string][]string{"full": {"fzf"}, "minimal": {"fzf"}},
	})
	a.tab = 3
	tt := ui.NewTester(a.view, 920, 720)
	if err := tt.Click("Spotify.Spotify"); err != nil {
		t.Fatal(err)
	}
	sel := a.selection()
	if got := sel["winget>"].([]string); !slices.Equal(got, []string{"Git.Git"}) {
		t.Errorf("winget> %q", got)
	}
	if got := sel["winget-elevated>"].([]string); got == nil || len(got) != 0 {
		t.Errorf("an empty list must stay [] for PowerShell, got %#v", got)
	}
	if sel["scoop profile>"] != "full" {
		t.Errorf("scoop profile> %v", sel["scoop profile>"])
	}
	a.profile = "minimal"
	if got := a.selection()["winget>"].([]string); !slices.Equal(got, []string{"Git.Git"}) {
		t.Errorf("minimal winget> %q", got)
	}
}

// Saves every page as PNGs to look at, with the real repository:
// INSTALLER_SNAPSHOT=/tmp/shot go test -run Snapshot
// Text needs Pango (on NixOS: pango, glib, cairo, fontconfig, harfbuzz in LD_LIBRARY_PATH).
func TestSnapshot(t *testing.T) {
	prefix := os.Getenv("INSTALLER_SNAPSHOT")
	if prefix == "" {
		t.Skip("INSTALLER_SNAPSHOT not set")
	}
	r, err := loadRepo("..")
	if err != nil {
		t.Fatal(err)
	}
	a := newApp()
	a.setRepo(r)
	a.keyOK = true
	a.deps[0].Path = `C:\Program Files\Git\cmd\git.exe`
	a.lines = []string{"> winget install -e --id GnuPG.Gpg4win", "Successfully installed"}
	for _, dark := range []bool{true, false} {
		tt := ui.NewTesterWith(a.view, 1000, 760, ui.TesterOptions{Dark: dark})
		for i := range steps {
			a.tab = i
			if i == 2 {
				a.profile = "custom"
			}
			tt.Frame()
			f, err := os.Create(fmt.Sprintf("%s-%d-%v.png", prefix, i, map[bool]string{true: "dark", false: "light"}[dark]))
			if err != nil {
				t.Fatal(err)
			}
			png.Encode(f, tt.Image())
			f.Close()
		}
	}
}
