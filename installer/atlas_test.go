package main

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"sync/atomic"
	"testing"

	"github.com/egoist/mygo/ui"
)

// The embedded pin is the repository's: a bump of packages/windows/system/atlas.json
// that forgets installer/atlas.json would send the installer to an old Atlas.
func TestAtlasPinMatchesRepo(t *testing.T) {
	b, err := os.ReadFile("../packages/windows/system/atlas.json")
	if err != nil {
		t.Fatal(err)
	}
	var repo atlasPin
	if err := json.Unmarshal(b, &repo); err != nil {
		t.Fatal(err)
	}
	got, err := atlasPinned()
	if err != nil {
		t.Fatal(err)
	}
	if got != repo {
		t.Errorf("installer/atlas.json %+v differs from packages/windows/system/atlas.json %+v: copy it over", got, repo)
	}
}

func TestReadAtlas(t *testing.T) {
	write := func(windir, rel, body string) {
		p := filepath.Join(windir, rel)
		if err := os.MkdirAll(filepath.Dir(p), 0o755); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(p, []byte(body), 0o644); err != nil {
			t.Fatal(err)
		}
	}
	for _, tc := range []struct {
		name  string
		files map[string]string
		want  atlasStatus
	}{
		{"no Atlas", nil, atlasStatus{}},
		{"completed install", map[string]string{`AtlasOS/state.json`: `{"installedVersion":"0.6.1","mode":"Fresh"}`}, atlasStatus{atlasInstalled, "0.6.1"}},
		{"install in progress", map[string]string{`AtlasOS/Install/active.json`: `{"status":"Running"}`}, atlasStatus{State: atlasRunning}},
		{"update in progress wins over the old record", map[string]string{
			`AtlasOS/state.json`:          `{"installedVersion":"0.5.0"}`,
			`AtlasOS/Install/active.json`: `{"status":"Capturing"}`,
		}, atlasStatus{State: atlasRunning}},
		{"before 0.6: only the modules folder", map[string]string{`AtlasModules/x.txt`: ""}, atlasStatus{State: atlasInstalled}},
		{"unreadable state, no folder", map[string]string{`AtlasOS/state.json`: `{not json`}, atlasStatus{}},
	} {
		dir := t.TempDir()
		for rel, body := range tc.files {
			write(dir, rel, body)
		}
		if got := readAtlas(dir); got != tc.want {
			t.Errorf("%s: %+v, want %+v", tc.name, got, tc.want)
		}
	}
}

func TestUnsupportedEdition(t *testing.T) {
	for edition, bad := range map[string]bool{
		"Professional": false, "Education": false, "Enterprise": false, "ProfessionalWorkstation": false,
		"Core": true, "CoreN": true, "CoreSingleLanguage": true, // Home
		"EnterpriseS":    true, // LTSC
		"ServerStandard": true, "ServerDatacenter": true,
	} {
		if got := unsupportedEdition(edition); got != bad {
			t.Errorf("%s: unsupported %v, want %v", edition, got, bad)
		}
	}
}

// The Manager is only ever handed over with the pinned SHA-256: a download that
// does not match is gone, and one already there that does is not fetched again.
func TestAtlasManager(t *testing.T) {
	body := []byte("pretend AtlasManager.exe")
	sum := sha256.Sum256(body)
	pin := atlasPin{Version: "9.9", SHA256: hex.EncodeToString(sum[:])}
	var hits atomic.Int32
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) { hits.Add(1); w.Write(body) }))
	defer srv.Close()
	pin.URL = srv.URL

	bad := pin
	bad.SHA256 = strings.Repeat("0", 64)
	dir := t.TempDir()
	if _, err := atlasManager(bad, dir); err == nil || !strings.Contains(err.Error(), "mismatch") {
		t.Fatalf("wrong SHA-256 accepted: %v", err)
	}
	if left, _ := filepath.Glob(filepath.Join(dir, "*")); len(left) != 0 {
		t.Errorf("a download that did not match was left behind: %v", left)
	}

	exe, err := atlasManager(pin, dir)
	if err != nil {
		t.Fatal(err)
	}
	if got, _ := os.ReadFile(exe); string(got) != string(body) || filepath.Base(exe) != "AtlasManager-9.9.exe" {
		t.Errorf("downloaded %q to %s", got, exe)
	}
	before := hits.Load()
	if _, err := atlasManager(pin, dir); err != nil || hits.Load() != before {
		t.Errorf("a verified file was fetched again (%v, %d hits)", err, hits.Load()-before)
	}
	if err := os.WriteFile(exe, []byte("tampered"), 0o755); err != nil {
		t.Fatal(err)
	}
	if _, err := atlasManager(pin, dir); err != nil || hits.Load() == before {
		t.Errorf("a file that no longer matches was kept (%v)", err)
	}
	if got, _ := os.ReadFile(exe); string(got) != string(body) {
		t.Errorf("tampered file not replaced: %q", got)
	}
}

// Windows starts at Atlas; Linux never has the page.
func TestAtlasPage(t *testing.T) {
	if p := newAppFor("windows").pages(); p[0].id != "atlas" || p[1].id != "setup" {
		t.Errorf("Windows rail starts %v", p[:2])
	}
	l := newAppFor("linux")
	l.linuxOS = osInfo{id: "fedora"}
	for _, p := range l.pages() {
		if p.id == "atlas" {
			t.Errorf("Atlas page on Linux: %v", l.pages())
		}
	}

	a := newAppFor("windows")
	tt := ui.NewTester(a.view, 1000, 900)
	if !tt.HasText("Download and open Atlas Manager " + mustPin(t).Version) {
		t.Fatalf("Atlas page: %q", tt.Texts())
	}
	for state, want := range map[atlasStatus]string{
		{}:                    "Not installed.",
		{State: atlasRunning}: "has not finished",
		{State: atlasInstalled, Version: "0.6.1"}: "Installed",
		{State: atlasInstalled}:                   "older Atlas",
	} {
		a.setAtlas(state, "Professional", false)
		tt.Frame()
		if !hasTextPart(tt, want) {
			t.Errorf("state %+v: no %q in %q", state, want, tt.Texts())
		}
	}
	a.setAtlas(atlasStatus{}, "Core", false)
	tt.Frame()
	if !hasTextPart(tt, "does not support this edition") {
		t.Errorf("Home edition not flagged: %q", tt.Texts())
	}
}

// A PC that already has Atlas starts on Setup; one without it, or one the user
// already moved, stays where it is.
func TestAtlasStartupSkip(t *testing.T) {
	installed := atlasStatus{State: atlasInstalled, Version: "0.6.1"}
	a := newAppFor("windows")
	a.setAtlas(installed, "Professional", true)
	if a.pages()[a.tab].id != "setup" {
		t.Errorf("with Atlas: on %q, want setup", a.pages()[a.tab].id)
	}
	a = newAppFor("windows")
	a.setAtlas(atlasStatus{}, "Professional", true)
	if a.pages()[a.tab].id != "atlas" {
		t.Errorf("without Atlas: on %q, want atlas", a.pages()[a.tab].id)
	}
	a = newAppFor("windows")
	a.goTo("profile")
	a.setAtlas(installed, "Professional", true)
	if a.pages()[a.tab].id != "profile" {
		t.Errorf("the user was moved from profile to %q", a.pages()[a.tab].id)
	}
	a = newAppFor("windows")
	a.setAtlas(installed, "Professional", false) // Check again, not startup
	if a.pages()[a.tab].id != "atlas" {
		t.Errorf("Check again moved the page to %q", a.pages()[a.tab].id)
	}
}

func mustPin(t *testing.T) atlasPin {
	t.Helper()
	p, err := atlasPinned()
	if err != nil {
		t.Fatal(err)
	}
	return p
}

// hasTextPart reports whether some text of the frame contains part.
func hasTextPart(tt *ui.Tester, part string) bool {
	for _, s := range tt.Texts() {
		if strings.Contains(s, part) {
			return true
		}
	}
	return false
}
