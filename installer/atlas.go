package main

// The Atlas step on Windows. Atlas (https://atlasos.net) comes first, before
// anything else, because it wants a fresh Windows 11. It is applied by
// AtlasManager.exe, a GUI that updates Windows, restarts the PC several times
// and asks for four Windows Security switches to be turned off by hand, so the
// installer does not drive it: it says where the PC stands, downloads the
// pinned Manager, checks its SHA-256 and opens it. The same as `install-atlas`
// (Documents/PowerShell/Functions/atlas.ps1), and docs/install/windows-atlas.md
// has the choices to make in it.

import (
	"crypto/sha256"
	_ "embed"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/egoist/mygo/ui"
)

// atlas.json is a copy of packages/windows/system/atlas.json: the installer
// runs before the repository is cloned. TestAtlasPinMatchesRepo keeps them equal.
//
//go:embed atlas.json
var atlasJSON []byte

// atlasPin is the AtlasManager.exe release the dotfiles are pinned to.
type atlasPin struct {
	Version string `json:"version"`
	URL     string `json:"url"`
	SHA256  string `json:"sha256"`
}

func atlasPinned() (atlasPin, error) {
	var p atlasPin
	if err := json.Unmarshal(atlasJSON, &p); err != nil {
		return p, fmt.Errorf("atlas.json: %w", err)
	}
	if p.Version == "" || p.URL == "" || len(p.SHA256) != 64 {
		return p, errors.New("atlas.json: version, url and sha256 are required")
	}
	return p, nil
}

type atlasState int

const (
	atlasNone      atlasState = iota // no Atlas
	atlasRunning                     // an install started and has not completed
	atlasInstalled                   // a completed install
)

// atlasStatus is where the PC stands with Atlas.
type atlasStatus struct {
	State   atlasState
	Version string // installed version; "" for an Atlas older than 0.6, which kept no record of it
}

// readAtlas looks at the records Atlas keeps under windir (Atlas's own
// docs/install-state.md): Install\active.json exists while an install is in
// progress, and state.json holds the installed version of a completed one.
// Atlas before 0.6 wrote neither; its AtlasModules folder is what is left.
func readAtlas(windir string) atlasStatus {
	if _, err := os.Stat(filepath.Join(windir, "AtlasOS", "Install", "active.json")); err == nil {
		return atlasStatus{State: atlasRunning}
	}
	if b, err := os.ReadFile(filepath.Join(windir, "AtlasOS", "state.json")); err == nil {
		var s struct {
			InstalledVersion string `json:"installedVersion"`
		}
		if json.Unmarshal(b, &s) == nil && s.InstalledVersion != "" {
			return atlasStatus{State: atlasInstalled, Version: s.InstalledVersion}
		}
	}
	if _, err := os.Stat(filepath.Join(windir, "AtlasModules")); err == nil {
		return atlasStatus{State: atlasInstalled}
	}
	return atlasStatus{}
}

// editionRe matches the EditionIDs Atlas does not support: Home (Core*), LTSC
// (ending in S) and Server. Pro, Education and Enterprise are fine.
var editionRe = regexp.MustCompile(`^Core|S$|^Server`)

func unsupportedEdition(edition string) bool { return editionRe.MatchString(edition) }

// fileSHA256 is the hex SHA-256 of the file at path.
func fileSHA256(path string) (string, error) {
	f, err := os.Open(path)
	if err != nil {
		return "", err
	}
	defer f.Close()
	h := sha256.New()
	if _, err := io.Copy(h, f); err != nil {
		return "", err
	}
	return hex.EncodeToString(h.Sum(nil)), nil
}

// atlasManager is the pinned AtlasManager.exe in dir: the one already there if
// it has the pinned SHA-256, else a fresh download that has it.
func atlasManager(p atlasPin, dir string) (string, error) {
	exe := filepath.Join(dir, "AtlasManager-"+p.Version+".exe")
	if sum, err := fileSHA256(exe); err == nil && strings.EqualFold(sum, p.SHA256) {
		return exe, nil
	}
	os.Remove(exe)
	return exe, fetchVerified(p.URL, p.SHA256, exe)
}

// checkAtlas reads the Atlas records and the Windows edition, off the main
// thread. startup is true for the first reading, when the page may skip ahead.
func (a *app) checkAtlas(startup bool) {
	if a.goos != "windows" {
		return
	}
	st, edition := readAtlas(os.Getenv("windir")), windowsEdition()
	a.post(func() { a.setAtlas(st, edition, startup) })
}

// setAtlas keeps what checkAtlas read. At startup, a PC that already has Atlas
// moves on to Setup, as this step is done, unless the user already went
// somewhere else.
func (a *app) setAtlas(st atlasStatus, edition string, startup bool) {
	a.atlas, a.edition = st, edition
	if startup && st.State == atlasInstalled && a.pages()[a.tab].id == "atlas" {
		a.goTo("setup")
	}
}

// openAtlas downloads the pinned Atlas Manager, checks it and opens it.
func (a *app) openAtlas() error {
	p, err := atlasPinned()
	if err != nil {
		return err
	}
	a.logf("Atlas Manager %s", p.Version)
	exe, err := atlasManager(p, os.TempDir())
	if err != nil {
		return err
	}
	a.logf("AtlasManager %s verified (SHA-256).", p.Version)
	// Start-Process, not os/exec: Atlas Manager asks for administrator rights,
	// which only ShellExecute can start from here. It returns at once.
	if err := a.run(false, "powershell.exe", "-NoProfile", "-Command",
		"Start-Process -FilePath '"+strings.ReplaceAll(exe, "'", "''")+"'"); err != nil {
		return err
	}
	a.post(func() {
		a.status, a.statusErr = "Atlas Manager is open. When Atlas is applied, open this installer again: it will go on from Setup.", false
	})
	return nil
}

func (a *app) atlasView(c *ui.Context) {
	pin, _ := atlasPinned()
	a.card(c, func() {
		switch { // no row when the edition could not be read: the banner names the requirement
		case a.edition == "":
		case unsupportedEdition(a.edition):
			a.listItem(c, false, "Windows "+a.edition, "Atlas does not support this edition: it needs Pro, Education or Enterprise.")
		default:
			a.listItem(c, true, "Windows "+a.edition, "A supported edition.")
		}
		switch st := a.atlas; {
		case st.State == atlasRunning:
			a.listItem(c, false, "Atlas", "An install was started and has not finished. Open Atlas Manager to continue it.")
		case st.State == atlasInstalled && st.Version != "":
			body := "Installed"
			if st.Version != pin.Version {
				body += "; these dotfiles pin " + pin.Version + ". Atlas Manager can update it: Update to Atlas, Keep my choices."
			}
			a.listItem(c, true, "Atlas "+st.Version, body)
		case st.State == atlasInstalled:
			a.listItem(c, true, "Atlas", "An older Atlas is installed. Atlas Manager can update it.")
		default:
			a.listItem(c, false, "Atlas", "Not installed.")
		}
	})
	a.banner(c, info, "Atlas needs Windows 11 Pro, Education or Enterprise, and wants it fresh: it removes OneDrive and restarts the PC several times. Back up first. Skip this step if the PC has Atlas already or you do not want it.")
	// The actions come before the instructions, so they are not below the fold.
	ui.Row(c).Gap(8).Children(func() {
		label := "Download and open Atlas Manager " + pin.Version
		if a.atlas.State == atlasInstalled {
			label = "Open Atlas Manager " + pin.Version + " to update"
		}
		if a.button(c, filled, label, a.busy != "") {
			a.step("Opening Atlas Manager", a.openAtlas)
		}
		if a.button(c, outlined, "Check again", a.busy != "") {
			a.step("Checking Atlas", func() error { a.checkAtlas(false); return nil })
		}
	})
	a.card(c, func() {
		a.sectionTitle(c, "In Atlas Manager")
		a.muted(c, "First install: choose Create an Atlas ISO and install Windows from it. On a Windows you just installed from Microsoft's media: choose Install Atlas.")
		a.muted(c, "Your choices: keep Microsoft Defender and Windows' processor protections, as Atlas recommends.")
		a.muted(c, "Windows Security: turn off Tamper Protection, Real-time protection, Cloud-delivered protection and Automatic sample submission yourself. Atlas Manager never changes them.")
		a.muted(c, "The PC restarts. Open this installer again afterwards: it sees Atlas and goes on from Setup.")
	})
}
