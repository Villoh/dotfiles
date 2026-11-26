package main

import (
	"image/png"
	"os"
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

func TestLineWriter(t *testing.T) {
	var lines []string
	w := &lineWriter{log: func(s string) { lines = append(lines, s) }}
	w.Write([]byte("a\r\n  -  \rb"))
	w.Write([]byte("c\nd"))
	w.Flush()
	if strings.Join(lines, ",") != "a,-,bc,d" {
		t.Errorf("lines %q", lines)
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
	// INSTALLER_SNAPSHOT=/tmp/x.png saves the frame to look at.
	if path := os.Getenv("INSTALLER_SNAPSHOT"); path != "" {
		a.profile = "full"
		tt.Advance(0)
		f, _ := os.Create(path)
		png.Encode(f, tt.Image())
		f.Close()
	}
}
