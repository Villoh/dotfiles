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
	r, err := loadRepo("..", "windows")
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
	// On Windows it lists $common and $windowsOnly, never a Linux-only module.
	if slices.Contains(r.Modules, "dms") {
		t.Errorf("Linux-only module dms listed: %v", r.Modules)
	}
	// Minimal keeps the desktop for new users and turns off the extras.
	if slices.Contains(r.MinimalOff, "aether") || !slices.Contains(r.MinimalOff, "warp") {
		t.Errorf("minimal turns off %v", r.MinimalOff)
	}
	if len(r.Winget["full"]) == 0 || len(r.Winget["minimal"]) == 0 || len(r.Scoop["full"]) == 0 || len(r.Elevated) == 0 {
		t.Errorf("package lists: winget %d/%d scoop %d elevated %d",
			len(r.Winget["minimal"]), len(r.Winget["full"]), len(r.Scoop["full"]), len(r.Elevated))
	}
}

// On Linux it lists $common and $linuxOnly, and no package lists: NixOS
// installs Linux's packages.
func TestLoadRepoLinux(t *testing.T) {
	r, err := loadRepo("..", "linux")
	if err != nil {
		t.Fatal(err)
	}
	for _, m := range []string{"zed", "zsh", "dms", "ai_agents", "mail"} {
		if !slices.Contains(r.Modules, m) {
			t.Errorf("module %s missing from %v", m, r.Modules)
		}
	}
	if slices.Contains(r.Modules, "aether") || slices.Contains(r.Modules, "altsnap") {
		t.Errorf("Windows-only module listed: %v", r.Modules)
	}
	if slices.Contains(r.Modules, "aerc") {
		t.Errorf("retired module aerc listed: %v", r.Modules)
	}
	if len(r.Winget["full"])+len(r.Scoop["full"])+len(r.Elevated) != 0 {
		t.Errorf("package lists on Linux: %v %v %v", r.Winget, r.Scoop, r.Elevated)
	}
}

// Linux has no Packages page, and Setup cannot install tools: it says how.
func TestLinuxSetup(t *testing.T) {
	a := newAppFor("linux")
	a.linuxOS = osInfo{id: "nixos", nixos: true} // whatever this machine runs
	for _, p := range a.pages() {
		if p.id == "packages" {
			t.Errorf("Linux pages %v", a.pages())
		}
	}
	if a.pages()[0].id != "system" {
		t.Errorf("NixOS starts at %q, want the System page", a.pages()[0].id)
	}
	a.goTo("setup")
	// NixOS installs nothing: Setup shows the Home Manager lines instead.
	tt := ui.NewTester(a.view, 1000, 760)
	if !tt.HasText("Install by hand") || !tt.HasText("Clone the repository") {
		t.Errorf("NixOS Setup page: %q", tt.Texts())
	}
	err := a.prepare() // no tool resolved yet
	if err == nil || !strings.Contains(err.Error(), "home.packages") {
		t.Errorf("prepare with Git missing: %v", err)
	}
	// Elsewhere it offers to install them (prepare found this machine's tools).
	a.linuxOS, a.deps = osInfo{id: "fedora"}, defaultDeps("linux")
	a.goTo("setup")
	tt.Frame()
	if !tt.HasText("Install missing tools and clone") || tt.HasText("Install by hand") {
		t.Errorf("Fedora Setup page: %q", tt.Texts())
	}
}

// The System page exists on NixOS only, and Switch waits for a passing test.
func TestNixosSystemPage(t *testing.T) {
	a := newAppFor("linux")
	a.linuxOS = osInfo{id: "fedora"}
	if a.pages()[0].id == "system" {
		t.Errorf("System page on Fedora: %v", a.pages())
	}
	a.linuxOS = osInfo{id: "nixos", nixos: true}
	a.nixos = nixosCfg{url: "u", dir: "/d", host: "h"}
	tt := ui.NewTester(a.view, 1000, 760)
	if !tt.HasText("Clone and test") || !tt.HasText("Switch") {
		t.Fatalf("System page: %q", tt.Texts())
	}
	if err := a.nixosRebuild("test", nixosCfg{}); err == nil {
		t.Error("empty configuration accepted")
	}
	dir := t.TempDir()
	if err := os.WriteFile(filepath.Join(dir, "x"), nil, 0o644); err != nil {
		t.Fatal(err)
	}
	if err := a.nixosRebuild("test", nixosCfg{url: "u", dir: dir, host: "h"}); err == nil || !strings.Contains(err.Error(), "no flake.nix") {
		t.Errorf("directory in use: %v", err)
	}
}

func TestNixosCommands(t *testing.T) {
	c := nixosCfg{url: "https://x/y", dir: "/d", host: "box"}
	if got := strings.Join(cloneCmd(true, c), " "); got != "git clone --recurse-submodules https://x/y /d" {
		t.Errorf("clone with git: %s", got)
	}
	if got := strings.Join(cloneCmd(false, c), " "); !strings.Contains(got, "nix --extra-experimental-features nix-command flakes shell nixpkgs#git -c git clone") {
		t.Errorf("clone without git: %s", got)
	}
	if got := strings.Join(rebuildCmd("test", c), " "); got != "pkexec /run/current-system/sw/bin/nixos-rebuild test --flake /d#box --option experimental-features nix-command flakes" {
		t.Errorf("rebuild: %s", got)
	}
	home, _ := os.UserHomeDir()
	if got, err := (nixosCfg{url: " u ", dir: "~/cfg", host: "h"}).clean(); err != nil || got.dir != filepath.Join(home, "cfg") || got.url != "u" {
		t.Errorf("clean: %+v %v", got, err)
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

// Full and minimal show their modules; changing one switches to custom and
// keeps what the profile enabled, its package lists too.
func TestModulesFollowProfile(t *testing.T) {
	a := newAppFor("windows")
	a.setRepo(repoInfo{Modules: []string{"zed", "git", "aether"}, MinimalOff: []string{"aether"}})
	a.tab, a.profile = 2, "minimal"
	tt := ui.NewTester(a.view, 1000, 760)
	if !tt.HasText("Modules  2/3") {
		t.Fatalf("minimal shows no module count: %q", tt.Texts())
	}
	if err := tt.Click("zed"); err != nil {
		t.Fatal(err)
	}
	if a.profile != "custom" || a.pkgVariant != "minimal" {
		t.Errorf("profile %s, package lists %s", a.profile, a.pkgVariant)
	}
	if a.modules["zed"] || !a.modules["git"] || a.modules["aether"] {
		t.Errorf("modules %v", a.modules)
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
	a := newAppFor("windows")
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
// INSTALLER_SNAPSHOT=/tmp/shot go test -run Snapshot (INSTALLER_GOOS=linux for Linux's pages)
// Text needs Pango (on NixOS: pango, glib, cairo, fontconfig, harfbuzz in LD_LIBRARY_PATH).
func TestSnapshot(t *testing.T) {
	prefix := os.Getenv("INSTALLER_SNAPSHOT")
	if prefix == "" {
		t.Skip("INSTALLER_SNAPSHOT not set")
	}
	goos := os.Getenv("INSTALLER_GOOS")
	if goos == "" {
		goos = "windows"
	}
	r, err := loadRepo("..", goos)
	if err != nil {
		t.Fatal(err)
	}
	a := newAppFor(goos)
	a.setRepo(r)
	a.keyOK = true
	a.deps[0].Path = `C:\Program Files\Git\cmd\git.exe`
	a.lines = []string{"> winget install -e --id GnuPG.Gpg4win", "Successfully installed"}
	for _, dark := range []bool{true, false} {
		tt := ui.NewTesterWith(a.view, 1000, 760, ui.TesterOptions{Dark: dark})
		for i, p := range a.pages() {
			a.tab = i
			if p.id == "profile" {
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
