// Command installer is a GUI for bootstrapping these dotfiles on Windows:
// it installs Git, Gpg4win and chezmoi, clones the repository, imports the
// GPG key, answers chezmoi's init prompts, picks the packages that
// run_once_00_windows-install would ask for with fzf, and runs chezmoi apply.
package main

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"slices"
	"strings"

	"github.com/egoist/mygo"
	"github.com/egoist/mygo/ui"
)

const (
	modePersonal  = "personal"
	modeSecondary = "secondary"
	maxLogLines   = 2000
)

// pkgList is one package manager's checklist; everything starts chosen.
type pkgList struct {
	key, title string // key is the fzf prompt of run_once_00_windows-install
	off        map[string]bool
	query      string
}

type app struct {
	win *mygo.Window // nil in tests

	tab       int
	busy      string // title of the running step, "" when idle
	status    string
	lines     []string
	logState  ui.ListState
	deps      []dep
	sourceDir string
	repo      repoInfo
	repoOK    bool

	mode               string
	keyFile, trustFile string
	keyOK              bool
	profile            string
	secrets            bool
	modules            map[string]bool
	pkgVariant         string // package lists for the custom profile
	pkgTab             int
	pkgs               []*pkgList
}

func newApp() *app {
	home, _ := os.UserHomeDir()
	a := &app{
		deps:       defaultDeps(),
		sourceDir:  filepath.Join(home, ".local", "share", "chezmoi"),
		mode:       modePersonal,
		profile:    "full",
		modules:    map[string]bool{},
		pkgVariant: "full",
		pkgs: []*pkgList{
			{key: "winget>", title: "winget", off: map[string]bool{}},
			{key: "winget-elevated>", title: "winget (elevated)", off: map[string]bool{}},
			{key: "scoop>", title: "scoop", off: map[string]bool{}},
		},
	}
	a.logState.FollowEnd = true
	return a
}

// post changes the state from any goroutine and redraws.
func (a *app) post(fn func()) {
	if a.win == nil {
		fn()
		return
	}
	a.win.Update(fn)
}

// sync reads or changes the state on the main thread and waits.
func (a *app) sync(fn func()) {
	if a.win == nil {
		fn()
		return
	}
	mygo.RunOnMain(fn)
}

func (a *app) logLine(s string) {
	a.post(func() {
		a.lines = append(a.lines, s)
		if n := len(a.lines) - maxLogLines; n > 0 {
			a.lines = slices.Delete(a.lines, 0, n)
		}
	})
}

func (a *app) logf(format string, args ...any) { a.logLine(fmt.Sprintf(format, args...)) }

func (a *app) setRepo(r repoInfo) {
	a.repo, a.repoOK = r, true
	for _, m := range r.Modules {
		if _, ok := a.modules[m]; !ok {
			a.modules[m] = true
		}
	}
}

// variant is the package list (minimal or full) the profile installs.
func (a *app) variant() string {
	if a.profile == "custom" {
		return a.pkgVariant
	}
	return a.profile
}

func (a *app) items(i int) []string {
	switch i {
	case 0:
		return a.repo.Winget[a.variant()]
	case 1:
		return a.repo.Elevated
	default:
		return a.repo.Scoop[a.variant()]
	}
}

func (a *app) chosen(i int) []string {
	out := []string{} // never null in JSON: PowerShell reads @($null) as one item
	for _, id := range a.items(i) {
		if !a.pkgs[i].off[id] {
			out = append(out, id)
		}
	}
	return out
}

// selection is the file run_once_00_windows-install reads, keyed by the fzf
// prompt each answer replaces.
func (a *app) selection() map[string]any {
	sel := map[string]any{"winget profile>": a.variant(), "scoop profile>": a.variant()}
	for i, p := range a.pkgs {
		sel[p.key] = a.chosen(i)
	}
	return sel
}

func (a *app) view(c *ui.Context) {
	t := c.Theme()
	ui.Column(c).Fill().Padding(16).Gap(12).Children(func() {
		ui.Row(c).Gap(8).Children(func() {
			ui.Text(c, "Villoh/dotfiles installer").FontSize(20).Bold()
			ui.Spacer(c)
			if a.busy != "" {
				ui.Spinner(c)
				ui.Text(c, a.busy+"...").TextColor(t.TextMuted)
			}
		})
		ui.Tabs(c, &a.tab, "1. Prerequisites", "2. GPG key", "3. Profile", "4. Packages", "5. Install")
		ui.Scroll(c.Key(a.tab)).Grow(1).Gap(12).Children(func() {
			switch a.tab {
			case 0:
				a.prereqView(c)
			case 1:
				a.keyView(c)
			case 2:
				a.profileView(c)
			case 3:
				a.packagesView(c)
			case 4:
				a.installView(c)
			}
		})
		if a.status != "" {
			ui.Text(c, a.status).TextColor(t.Warning)
		}
		ui.List(c, &a.logState, len(a.lines), func(i int) {
			ui.Text(c, a.lines[i]).FontSize(12).TextColor(t.TextMuted)
		}).Height(150).Padding(8).Background(t.Surface).Radius(6).Children(func() {
			if len(a.lines) == 0 {
				ui.Text(c, "Log").FontSize(12).TextColor(t.TextMuted)
			}
		})
	})
}

func (a *app) muted(c *ui.Context, s string) {
	ui.Text(c, s).TextColor(c.Theme().TextMuted)
}

func (a *app) needRepo(c *ui.Context) bool {
	if !a.repoOK {
		a.muted(c, "Run step 1 first: the choices here come from the cloned repository.")
	}
	return a.repoOK
}

func (a *app) prereqView(c *ui.Context) {
	t := c.Theme()
	a.muted(c, "Installs the bootstrap tools with winget and clones the repository with Git.")
	for _, d := range a.deps {
		ui.Row(c).Gap(12).Children(func() {
			ui.Text(c, d.Name).Width(140)
			if d.Path != "" {
				ui.Text(c, "✓ installed").TextColor(t.Success).Width(110)
				a.muted(c, d.Path)
			} else {
				ui.Text(c, "✗ missing").TextColor(t.Danger).Width(110)
				a.muted(c, "winget: "+d.WingetID)
			}
		})
	}
	ui.Row(c).Gap(12).Children(func() {
		ui.Text(c, "Repository").Width(140)
		if a.repoOK {
			ui.Text(c, "✓ cloned").TextColor(t.Success).Width(110)
		} else {
			ui.Text(c, "✗ not cloned").TextColor(t.Danger).Width(110)
		}
		a.muted(c, a.sourceDir)
	})
	ui.Row(c).Gap(8).Children(func() {
		if ui.PrimaryButton(c, "Install missing tools and clone").Disabled(a.busy != "").Clicked() {
			a.step("Preparing", a.prepare)
		}
		if ui.Button(c, "Check again").Disabled(a.busy != "").Clicked() {
			a.step("Checking", func() error { a.checkDeps(); return nil })
		}
	})
}

func (a *app) keyView(c *ui.Context) {
	t := c.Theme()
	ui.RadioGroup(c, func() {
		ui.Radio(c, &a.mode, modePersonal, "Personal: decrypt the encrypted files with my GPG key")
		ui.Radio(c, &a.mode, modeSecondary, "Secondary: skip encrypted files (identities, work config, secrets)")
	}).Gap(8).Label("Flow")
	if a.mode == modeSecondary {
		a.muted(c, "chezmoi apply will run with --exclude=encrypted. Configure Git and SSH for this machine yourself.")
		return
	}
	if !a.needRepo(c) {
		return
	}
	a.muted(c, "Import the private key and ownertrust from your secure backup. Never put them in the repository.")
	a.fileRow(c, "Secret key", &a.keyFile, "gpg-secret-<KEYID>.asc", []string{"asc", "gpg", "key"})
	a.fileRow(c, "Ownertrust", &a.trustFile, "gpg-ownertrust.txt (optional)", []string{"txt"})
	ui.Row(c).Gap(12).Children(func() {
		if ui.PrimaryButton(c, "Import").Disabled(a.busy != "" || a.keyFile == "").Clicked() {
			key, trust := a.keyFile, a.trustFile
			a.step("Importing key", func() error { return a.importKey(key, trust) })
		}
		if ui.Button(c, "Check again").Disabled(a.busy != "").Clicked() {
			a.step("Checking key", func() error { a.checkKey(); return nil })
		}
		if a.keyOK {
			ui.Text(c, "✓ key "+a.repo.Recipient+" available").TextColor(t.Success)
		} else {
			ui.Text(c, "✗ key "+a.repo.Recipient+" not found").TextColor(t.Danger)
		}
	})
}

func (a *app) fileRow(c *ui.Context, label string, path *string, placeholder string, exts []string) {
	ui.Row(c.Key(label)).Gap(8).Children(func() {
		ui.Text(c, label).Width(100)
		ui.TextInput(c, path).Placeholder(placeholder).Grow(1)
		if ui.Button(c, "Browse...").Clicked() && a.win != nil {
			go func() {
				paths, err := mygo.Dialog.Open(mygo.OpenDialogOptions{
					Parent: a.win, Title: label,
					Filters: []mygo.FileFilter{{Name: label, Extensions: exts}, {Name: "All files", Extensions: []string{"*"}}},
				})
				if err == nil && len(paths) > 0 {
					a.post(func() { *path = paths[0] })
				}
			}()
		}
	})
}

func (a *app) profileView(c *ui.Context) {
	if !a.needRepo(c) {
		return
	}
	ui.RadioGroup(c, func() {
		ui.Radio(c, &a.profile, "full", "full: every module for Windows, full package lists")
		ui.Radio(c, &a.profile, "minimal", "minimal: CLI and shell configs only ("+strings.Join(a.repo.MinimalOff, ", ")+" off)")
		ui.Radio(c, &a.profile, "custom", "custom: choose modules one by one")
	}).Gap(8).Label("Install profile")
	ui.Checkbox(c, &a.secrets, "Personal secrets (owner only: fetches API keys from Bitwarden)")
	if a.profile != "custom" {
		return
	}
	ui.Text(c, "Modules").Bold()
	ui.Row(c).Wrap().Gap(8).Children(func() {
		for _, m := range a.repo.Modules {
			on := a.modules[m]
			if ui.Checkbox(c.Key(m), &on, m).Width(170).Changed() {
				a.modules[m] = on
			}
		}
	})
}

func (a *app) packagesView(c *ui.Context) {
	if !a.needRepo(c) {
		return
	}
	if a.profile == "custom" {
		ui.Row(c).Gap(12).Children(func() {
			ui.Text(c, "Package lists")
			i := map[string]int{"minimal": 0, "full": 1}[a.pkgVariant]
			if ui.Segmented(c, &i, "minimal", "full").Changed() {
				a.pkgVariant = []string{"minimal", "full"}[i]
			}
		})
	} else {
		a.muted(c, "Package lists: "+a.variant()+" (from the install profile). mise and PowerShell modules are always installed.")
	}
	labels := make([]string, len(a.pkgs))
	for i, p := range a.pkgs {
		labels[i] = fmt.Sprintf("%s (%d/%d)", p.title, len(a.chosen(i)), len(a.items(i)))
	}
	ui.Tabs(c, &a.pkgTab, labels...)
	p := a.pkgs[a.pkgTab]
	var shown []string
	for _, id := range a.items(a.pkgTab) {
		if strings.Contains(strings.ToLower(id), strings.ToLower(p.query)) {
			shown = append(shown, id)
		}
	}
	ui.Row(c.Key(p.key)).Gap(8).Children(func() {
		ui.SearchField(c, &p.query).Placeholder("Filter " + p.title).Grow(1)
		if ui.Button(c, "All").Clicked() {
			for _, id := range shown {
				delete(p.off, id)
			}
		}
		if ui.Button(c, "None").Clicked() {
			for _, id := range shown {
				p.off[id] = true
			}
		}
	})
	ui.Column(c.Key(p.key + "/list")).Gap(2).Children(func() {
		for _, id := range shown {
			on := !p.off[id]
			if ui.Checkbox(c.Key(id), &on, id).Changed() {
				p.off[id] = !on
			}
		}
	})
}

func (a *app) installView(c *ui.Context) {
	if !a.needRepo(c) {
		return
	}
	row := func(k, v string) {
		ui.Row(c.Key(k)).Gap(12).Children(func() {
			ui.Text(c, k).Width(140)
			ui.Text(c, v)
		})
	}
	row("Flow", a.mode)
	row("Profile", a.profile)
	row("Secrets", fmt.Sprint(a.secrets))
	for i, p := range a.pkgs {
		row(p.title, fmt.Sprintf("%d of %d packages", len(a.chosen(i)), len(a.items(i))))
	}
	row("Source", a.sourceDir)
	ready := a.mode == modeSecondary || a.keyOK
	if !ready {
		ui.Text(c, "Import the GPG key first (step 2), or switch to the secondary flow.").TextColor(c.Theme().Warning)
	}
	a.muted(c, "chezmoi init runs here; chezmoi apply opens in a console window, where its scripts may ask questions and UAC may prompt.")
	if ui.PrimaryButton(c, "Install").Disabled(a.busy != "" || !ready).Clicked() {
		p := a.makePlan()
		a.step("Installing", func() error { return a.install(p) })
	}
}

func main() {
	a := newApp()
	mygo.App.WhenReady(func() {
		a.win = mygo.NewWindow(mygo.WindowOptions{
			Title: "Dotfiles installer", Width: 920, Height: 720, MinWidth: 720, MinHeight: 540,
			Content: ui.View(a.view),
		})
		go a.checkDeps()
	})
	if err := mygo.App.Run(); err != nil {
		log.Fatal(err)
	}
}
