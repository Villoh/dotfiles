package main

import (
	"errors"
	"fmt"
	"image/png"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"slices"
	"strings"
	"testing"
	"time"

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
	for _, m := range []string{"zed", "aether", "startup", "btop", "starship", "package_managers"} {
		if !slices.Contains(r.Modules, m) {
			t.Errorf("module %s missing from %v", m, r.Modules)
		}
	}
	// On Windows it lists $common and $windowsOnly, never a Linux-only module.
	if slices.Contains(r.Modules, "dms") {
		t.Errorf("Linux-only module dms listed: %v", r.Modules)
	}
	// Minimal keeps the desktop for new users and turns off the extras.
	if slices.Contains(r.MinimalOff, "aether") || !slices.Contains(r.MinimalOff, "warp") || !slices.Contains(r.MinimalOff, "ai_agents") {
		t.Errorf("minimal turns off %v", r.MinimalOff)
	}
	if len(r.Winget["full"]) == 0 || len(r.Winget["minimal"]) == 0 || len(r.Scoop["full"]) == 0 || len(r.Elevated) == 0 {
		t.Errorf("package lists: winget %d/%d scoop %d elevated %d",
			len(r.Winget["minimal"]), len(r.Winget["full"]), len(r.Scoop["full"]), len(r.Elevated))
	}
}

// mise: full is every tool for Windows (os-less or os = ["windows"]); minimal
// only the desktop apps, those with a Start Menu shortcut.
func TestMiseTools(t *testing.T) {
	r, err := loadRepo("..", "windows")
	if err != nil {
		t.Fatal(err)
	}
	full, minimal := r.Mise["full"], r.Mise["minimal"]
	for _, tool := range []string{"github:ViceVerse-cz/Serein", "aube", "bun", "npm:tokscale"} {
		if !slices.Contains(full, tool) {
			t.Errorf("mise full lacks %s: %v", tool, full)
		}
	}
	for _, tool := range []string{"claude", "github:PrimeIntellect-ai/prime-agent"} {
		if slices.Contains(full, tool) {
			t.Errorf("mise full has the Linux-only %s", tool)
		}
	}
	if !slices.Contains(minimal, "github:ViceVerse-cz/Serein") || slices.Contains(minimal, "aube") || len(minimal) >= len(full) {
		t.Errorf("mise minimal %v", minimal)
	}
}

// On Linux it lists $common and $linuxOnly, and no package lists: NixOS
// installs Linux's packages.
func TestLoadRepoLinux(t *testing.T) {
	r, err := loadRepo("..", "linux")
	if err != nil {
		t.Fatal(err)
	}
	for _, m := range []string{"zed", "zsh", "dms", "ai_agents", "mail", "package_managers"} {
		if !slices.Contains(r.Modules, m) {
			t.Errorf("module %s missing from %v", m, r.Modules)
		}
	}
	// NixOS owns these configs on Linux; opencode is part of ai_agents and bun,
	// uv and pnpm of package_managers.
	for _, m := range []string{"btop", "fastfetch", "starship", "alacritty", "opencode", "bun", "uv", "pnpm"} {
		if slices.Contains(r.Modules, m) {
			t.Errorf("module %s listed on Linux: %v", m, r.Modules)
		}
	}
	if slices.Contains(r.Modules, "aether") || slices.Contains(r.Modules, "altsnap") {
		t.Errorf("Windows-only module listed: %v", r.Modules)
	}
	if slices.Contains(r.Modules, "aerc") {
		t.Errorf("retired module aerc listed: %v", r.Modules)
	}
	// Minimal keeps the desktop on Linux too.
	if slices.Contains(r.MinimalOff, "dms") {
		t.Errorf("minimal turns off dms: %v", r.MinimalOff)
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

// The host is the flake's name, which need not be the machine's hostname.
func TestCheckHost(t *testing.T) {
	const hosts = `["desktop","zenbook"]`
	if err := checkHost(hosts, "zenbook"); err != nil {
		t.Errorf("known host: %v", err)
	}
	for _, host := range []string{"", "nixos-zenbook"} {
		err := checkHost(hosts, host)
		if err == nil || !strings.Contains(err.Error(), "desktop, zenbook") {
			t.Errorf("host %q: %v", host, err)
		}
	}
	if checkHost(`[]`, "x") == nil || checkHost(`oops`, "x") == nil {
		t.Error("empty or invalid host list accepted")
	}
	if got := strings.Join(hostsCmd("/d"), " "); !strings.HasSuffix(got, "eval --json /d#nixosConfigurations --apply builtins.attrNames") {
		t.Errorf("hostsCmd: %s", got)
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
	if got := strings.Join(rebuildCmd("test", c, "/p:/q"), " "); got != "pkexec env PATH=/p:/q /run/current-system/sw/bin/nixos-rebuild test --flake /d#box --option experimental-features nix-command flakes" {
		t.Errorf("rebuild: %s", got)
	}
	home, _ := os.UserHomeDir()
	if got, err := (nixosCfg{url: " u ", dir: "~/cfg", host: "h"}).clean(); err != nil || got.dir != filepath.Join(home, "cfg") || got.url != "u" {
		t.Errorf("clean: %+v %v", got, err)
	}
}

// The rail ends with the Log page on every OS. Expand, in the panel under any
// other page, opens it, and the rail goes back.
func TestLogPage(t *testing.T) {
	for _, goos := range []string{"windows", "linux"} {
		p := newAppFor(goos).pages()
		if p[len(p)-1].id != "log" {
			t.Errorf("%s: the rail ends with %q, want log", goos, p[len(p)-1].id)
		}
	}
	a := newAppFor("linux")
	a.linuxOS = osInfo{id: "fedora"}
	a.logLine("hello")
	tt := ui.NewTester(a.view, 1000, 760)
	if !tt.HasText("Prerequisites") {
		t.Fatalf("before: %q", tt.Texts())
	}
	if err := tt.Click("Expand"); err != nil {
		t.Fatal(err)
	}
	if a.pages()[a.tab].id != "log" || tt.HasText("Prerequisites") || !tt.HasText("hello") {
		t.Errorf("Log page: tab %d, %q", a.tab, tt.Texts())
	}
	if _, ok := tt.Find("Expand"); ok {
		t.Error("Expand on the Log page itself")
	}
	if err := tt.Click("Setup"); err != nil || a.pages()[a.tab].id != "setup" {
		t.Errorf("rail back to Setup: %v, tab %d", err, a.tab)
	}
	if got := a.logText(); got != "hello" {
		t.Errorf("logText %q", got)
	}
	// Copy says it copied, and goes back to Copy after a while.
	if err := tt.Click("Copy"); err != nil {
		t.Fatal(err)
	}
	if !a.justCopied("log") {
		t.Error("no copied sign after Copy")
	}
	if err := tt.Click("Copied"); err != nil { // the icon is now a check, named Copied
		t.Errorf("Copied button: %v", err)
	}
	a.copiedAt = time.Now().Add(-3 * time.Second)
	tt.Frame()
	if a.justCopied("log") {
		t.Error("still Copied after 3s")
	}
	if err := tt.Click("Copy"); err != nil {
		t.Errorf("Copy button did not come back: %v", err)
	}
}

// The log's own window shows the log, copy and save, and none of the main
// window's page or its expand and open-in-a-window buttons.
func TestLogWindowView(t *testing.T) {
	a := newAppFor("linux")
	a.linuxOS = osInfo{id: "fedora"}
	a.logLine("hello")
	main := ui.NewTester(a.view, 1000, 760)
	for _, name := range []string{"Copy", "Save the log", "Expand", "Open the log in its own window"} {
		if _, ok := main.Find(name); !ok {
			t.Errorf("main window has no %q button", name)
		}
	}
	own := ui.NewTester(a.logWindowView, 800, 500)
	if !own.HasText("hello") {
		t.Errorf("log window: %q", own.Texts())
	}
	for _, name := range []string{"Copy", "Save the log"} {
		if _, ok := own.Find(name); !ok {
			t.Errorf("log window has no %q button", name)
		}
	}
	for _, name := range []string{"Expand", "Open the log in its own window", "Check again"} {
		if _, ok := own.Find(name); ok {
			t.Errorf("log window has %q", name)
		}
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

// run_once_00_windows-install's Get-MiseTools and miseTools read the mise config
// with one rule: the script installs what the GUI offers.
func TestMiseToolsMatchScript(t *testing.T) {
	pwsh, err := exec.LookPath("pwsh")
	if err != nil {
		t.Skip("pwsh not installed")
	}
	b, err := os.ReadFile("../.chezmoiscripts/run_once_00_windows-install.ps1.tmpl")
	if err != nil {
		t.Fatal(err)
	}
	fn := regexp.MustCompile(`(?ms)^function Get-MiseTools \{.*?^\}`).Find(b)
	if fn == nil {
		t.Fatal("Get-MiseTools not found")
	}
	out, err := exec.Command(pwsh, "-NoProfile", "-Command",
		string(fn)+"; Get-MiseTools ../dot_config/mise/config.toml | Sort-Object -CaseSensitive").Output()
	if err != nil {
		t.Fatal(err)
	}
	got := strings.Fields(string(out))
	want, _ := miseTools("../dot_config/mise/config.toml")
	slices.Sort(got)
	if !slices.Equal(got, want) {
		t.Errorf("Get-MiseTools %v\nmiseTools      %v", got, want)
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
	a.goTo("profile")
	a.profile = "minimal"
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
		Mise:    map[string][]string{"full": {"bun", "github:yapfast/yapfast"}, "minimal": {"github:yapfast/yapfast"}},
	})
	a.goTo("packages")
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
	if got := sel["mise>"].([]string); !slices.Equal(got, []string{"bun", "github:yapfast/yapfast"}) {
		t.Errorf("mise> %q", got)
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

// Hovering and pressing a button must be easy to see: the pointer turns into a
// hand and the fill moves well away from the idle one (M3's 8% was too faint on
// the dark theme). The headless frame has no text, so the fill is all there is.
func TestButtonFeedback(t *testing.T) {
	a := newAppFor("windows") // its Setup button is filled; the Linux one may not be
	a.goTo("setup")
	tt := ui.NewTester(a.view, 1000, 760)
	r, ok := tt.Find("Install missing tools and clone")
	if !ok {
		t.Fatal("no Install button")
	}
	x, y := r.X+12, r.Y+r.H/2 // inside the pill, left of its text
	fill := func() [3]int {
		c := tt.Image().RGBAAt(int(x), int(y))
		return [3]int{int(c.R), int(c.G), int(c.B)}
	}
	far := func(a, b [3]int) int { return max(abs(a[0]-b[0]), abs(a[1]-b[1]), abs(a[2]-b[2])) }
	idle := fill()
	tt.Move(x, y)
	tt.Frame()
	hover := fill()
	if tt.Cursor() != ui.CursorPointer {
		t.Errorf("cursor over a button: %v, want the pointer", tt.Cursor())
	}
	tt.Press(x, y)
	tt.Frame()
	press := fill()
	tt.Release(x, y)
	if far(idle, hover) < 20 || far(hover, press) < 8 {
		t.Errorf("faint feedback: idle %v hover %v press %v", idle, hover, press)
	}
}

func abs(n int) int {
	if n < 0 {
		return -n
	}
	return n
}

// chezmoi is a portable winget package, which winget refuses to install in the
// user scope from the administrator session the installer runs in: it asks for
// the machine scope. The installers that already work are left alone.
func TestWingetInstallArgs(t *testing.T) {
	want := map[string]string{
		"Git.Git":         "install -e --id Git.Git --accept-package-agreements --accept-source-agreements --silent",
		"GnuPG.Gpg4win":   "install -e --id GnuPG.Gpg4win --accept-package-agreements --accept-source-agreements --silent",
		"twpayne.chezmoi": "install -e --id twpayne.chezmoi --scope machine --accept-package-agreements --accept-source-agreements --silent",
	}
	for _, d := range defaultDeps("windows") {
		if got := strings.Join(wingetInstallArgs(d), " "); got != want[d.WingetID] {
			t.Errorf("%s: %s\nwant %s", d.WingetID, got, want[d.WingetID])
		}
	}
}
