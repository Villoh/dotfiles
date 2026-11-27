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
	statusErr bool

	scheme     *scheme // M3 colors of the frame (m3.go)
	schemeSeed ui.Color
	schemeDark bool
	lines      []string
	logState   ui.ListState
	deps       []dep
	sourceDir  string
	repo       repoInfo
	repoOK     bool

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

// steps are the destinations of the navigation rail.
var steps = []struct{ icon, label, title, blurb string }{
	{"build", "Setup", "Prerequisites", "Installs Git, Gpg4win and chezmoi with winget, and clones the repository."},
	{"key", "GPG key", "GPG key", "Choose how to handle the encrypted files."},
	{"tune", "Profile", "Install profile", "What chezmoi deploys. Answers chezmoi init's prompts."},
	{"inventory_2", "Packages", "Packages", "What run_once_00_windows-install installs, instead of asking with fzf."},
	{"rocket_launch", "Install", "Install", "Review the choices and run chezmoi."},
}

// appTitle names the window (taskbar, Alt+Tab) and its title bar.
const appTitle = "Villoh/dotfiles installer"

const titleBarHeight = 40 // the window buttons MyGo draws fill it

// titleBar replaces the native one (TitleBarHidden): the app's surface up to
// the top edge, a drag handle, and room for the window buttons MyGo draws.
func (a *app) titleBar(c *ui.Context) {
	s := a.scheme
	bar := c.TitleBar()
	ui.Row(c).Height(max(bar.Height, titleBarHeight)).Padding(0, bar.Right, 0, bar.Left).DragWindow().Children(func() {
		ui.Row(c).Width(96).Justify(ui.Center).Children(func() { // centered over the rail
			ui.Icon(c, icons["terminal"]).FontSize(20).TextColor(s.Primary)
		})
		ui.Text(c, appTitle).MarginStart(8).FontSize(13).FontWeight(500).TextColor(s.OnSurfaceVariant).SingleLine()
	})
}

func (a *app) view(c *ui.Context) {
	a.themed(c)
	ui.Column(c).Fill().Children(func() {
		a.titleBar(c)
		a.body(c)
	})
}

func (a *app) body(c *ui.Context) {
	s := a.scheme
	ui.Row(c).Grow(1).FillWidth().Children(func() {
		// Navigation rail.
		ui.Column(c).Width(96).FillHeight().PaddingY(8).Gap(12).AlignItems(ui.Center).Children(func() {
			for i, st := range steps {
				a.railItem(c, i, st.icon, st.label)
			}
		})
		// Content.
		ui.Column(c).Grow(1).Shrink(1).FillHeight().Padding(8, 24, 16, 8).Gap(16).Children(func() {
			st := steps[a.tab]
			ui.Row(c).Gap(12).Children(func() {
				ui.Column(c).Gap(4).Grow(1).Shrink(1).Children(func() {
					ui.Text(c, st.title).FontSize(28).TextColor(s.OnSurface)
					ui.Text(c, st.blurb).FontSize(14).TextColor(s.OnSurfaceVariant)
				})
				if a.busy != "" {
					ui.Text(c, a.busy+"...").FontSize(14).TextColor(s.OnSurfaceVariant)
				}
			})
			if a.busy != "" {
				ui.Progress(c, -1).Label(a.busy)
			}
			ui.Scroll(c.Key(a.tab)).Grow(1).Gap(16).Children(func() {
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
				a.banner(c, a.statusErr, a.status)
			}
			a.logView(c)
		})
	})
}

func (a *app) logView(c *ui.Context) {
	s := a.scheme
	ui.Column(c).Height(160).Background(s.SurfaceContainer).Radius(16).Padding(12, 16).Gap(8).Children(func() {
		ui.Row(c).Gap(8).Children(func() {
			ui.Icon(c, icons["terminal"]).FontSize(18).TextColor(s.OnSurfaceVariant)
			ui.Text(c, "Log").FontSize(14).FontWeight(500).TextColor(s.OnSurfaceVariant)
		})
		ui.List(c, &a.logState, len(a.lines), func(i int) {
			ui.Text(c, a.lines[i]).FontSize(12).TextColor(s.OnSurfaceVariant)
		}).Grow(1).Children(func() {
			if len(a.lines) == 0 {
				ui.Text(c, "Nothing yet.").FontSize(12).TextColor(s.OnSurfaceVariant.Alpha(0.7))
			}
		})
	})
}

func (a *app) muted(c *ui.Context, text string) {
	ui.Text(c, text).FontSize(14).TextColor(a.scheme.OnSurfaceVariant)
}

func (a *app) sectionTitle(c *ui.Context, text string) {
	ui.Text(c, text).FontSize(16).FontWeight(500).TextColor(a.scheme.OnSurface)
}

func (a *app) needRepo(c *ui.Context) bool {
	if !a.repoOK {
		a.banner(c, true, "Run Setup first: the choices here come from the cloned repository.")
	}
	return a.repoOK
}

func (a *app) prereqView(c *ui.Context) {
	a.card(c, func() {
		for _, d := range a.deps {
			body := d.Path
			if d.Path == "" {
				body = "Missing. winget: " + d.WingetID
			}
			a.listItem(c, d.Path != "", d.Name, body)
		}
		repo := a.sourceDir
		if !a.repoOK {
			repo = "Not cloned yet: " + a.sourceDir
		}
		a.listItem(c, a.repoOK, "Repository", repo)
	})
	ui.Row(c).Gap(8).Children(func() {
		if a.button(c, filled, "Install missing tools and clone", a.busy != "") {
			a.step("Preparing", a.prepare)
		}
		if a.button(c, outlined, "Check again", a.busy != "") {
			a.step("Checking", func() error { a.checkDeps(); return nil })
		}
	})
}

func (a *app) keyView(c *ui.Context) {
	ui.Row(c).Gap(12).AlignItems(ui.Stretch).Children(func() {
		if a.choiceCard(c, a.mode == modePersonal, "person", "Personal",
			"Decrypt the encrypted files with my GPG key.") {
			a.mode = modePersonal
		}
		if a.choiceCard(c, a.mode == modeSecondary, "devices", "Secondary",
			"Skip encrypted files: identities, work config and secrets.") {
			a.mode = modeSecondary
		}
	})
	if a.mode == modeSecondary {
		a.muted(c, "chezmoi apply runs with --exclude=encrypted. Configure Git and SSH for this machine yourself.")
		return
	}
	if !a.needRepo(c) {
		return
	}
	a.card(c, func() {
		a.sectionTitle(c, "Import from your secure backup")
		a.muted(c, "Never put the key files in the repository.")
		a.fileRow(c, "Secret key", &a.keyFile, "gpg-secret-<KEYID>.asc", []string{"asc", "gpg", "key"})
		a.fileRow(c, "Ownertrust", &a.trustFile, "gpg-ownertrust.txt (optional)", []string{"txt"})
		ui.Row(c).Gap(8).Children(func() {
			if a.button(c, filled, "Import", a.busy != "" || a.keyFile == "") {
				key, trust := a.keyFile, a.trustFile
				a.step("Importing key", func() error { return a.importKey(key, trust) })
			}
			if a.button(c, outlined, "Check again", a.busy != "") {
				a.step("Checking key", func() error { a.checkKey(); return nil })
			}
		})
	})
	a.card(c, func() {
		if a.keyOK {
			a.listItem(c, true, "Key "+a.repo.Recipient, "Available to GnuPG")
		} else {
			a.listItem(c, false, "Key "+a.repo.Recipient, "Not found. Import it above.")
		}
	})
}

func (a *app) fileRow(c *ui.Context, label string, path *string, placeholder string, exts []string) {
	ui.Row(c.Key(label)).Gap(8).Children(func() {
		ui.TextInput(c, path).Placeholder(placeholder).Label(label).Grow(1).Height(40).Radius(8)
		if a.button(c, tonal, "Browse...", false) && a.win != nil {
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
	ui.Row(c).Gap(12).AlignItems(ui.Stretch).Children(func() {
		for _, p := range []struct{ id, body string }{
			{"full", "Every module for Windows and the full package lists."},
			{"minimal", "CLI and shell configs only. Turns off " + strings.Join(a.repo.MinimalOff, ", ") + "."},
			{"custom", "Choose the modules one by one."},
		} {
			if a.choiceCard(c, a.profile == p.id, "", p.id, p.body) {
				a.profile = p.id
			}
		}
	})
	a.card(c, func() {
		ui.Row(c).Gap(16).Children(func() {
			ui.Column(c).Gap(2).Grow(1).Shrink(1).Children(func() {
				ui.Text(c, "Personal secrets").FontSize(16).TextColor(a.scheme.OnSurface)
				a.muted(c, "Owner only: fetches API keys from Bitwarden.")
			})
			ui.Switch(c, &a.secrets).Label("Personal secrets")
		})
	})
	if a.profile != "custom" {
		return
	}
	a.card(c, func() {
		a.sectionTitle(c, "Modules")
		ui.Row(c).Wrap().Gap(8).Children(func() {
			for _, m := range a.repo.Modules {
				on := a.modules[m]
				a.filterChip(c, &on, m)
				a.modules[m] = on
			}
		})
	})
}

func (a *app) packagesView(c *ui.Context) {
	if !a.needRepo(c) {
		return
	}
	s := a.scheme
	if a.profile == "custom" {
		ui.Row(c).Gap(12).Children(func() {
			a.sectionTitle(c, "Package lists")
			i := map[string]int{"minimal": 0, "full": 1}[a.pkgVariant]
			if ui.Segmented(c, &i, "minimal", "full").Changed() {
				a.pkgVariant = []string{"minimal", "full"}[i]
			}
		})
	} else {
		a.muted(c, "Package lists: "+a.variant()+", from the install profile. mise and the PowerShell modules are always installed.")
	}
	ui.Row(c).Gap(8).Children(func() {
		for i, p := range a.pkgs {
			on := a.pkgTab == i
			label := fmt.Sprintf("%s  %d/%d", p.title, len(a.chosen(i)), len(a.items(i)))
			bg, fg := s.Surface.Alpha(0), s.OnSurfaceVariant
			if on {
				bg, fg = s.SecondaryContainer, s.OnSecondaryContainer
			}
			b := ui.ButtonBase(c.Key(p.key)).Label(p.title).AccessSelected(on).Role(ui.RoleTab).Height(32).PaddingX(16).Radius(full)
			if !on {
				b.Border(1, s.OutlineVariant)
			}
			b.Background(stateFill(b, bg, fg)).Children(func() {
				ui.Text(c, label).FontSize(14).FontWeight(500).TextColor(fg).SingleLine()
			})
			if b.Clicked() {
				a.pkgTab = i
			}
		}
	})
	p := a.pkgs[a.pkgTab]
	var shown []string
	for _, id := range a.items(a.pkgTab) {
		if strings.Contains(strings.ToLower(id), strings.ToLower(p.query)) {
			shown = append(shown, id)
		}
	}
	ui.Row(c.Key(p.key + "/search")).Gap(8).Children(func() {
		ui.SearchField(c, &p.query).Placeholder("Filter "+p.title).Grow(1).Height(48).Radius(full).
			Background(s.SurfaceContainerHigh).Border(0, s.Surface)
		if a.button(c, outlined, "All", false) {
			for _, id := range shown {
				delete(p.off, id)
			}
		}
		if a.button(c, outlined, "None", false) {
			for _, id := range shown {
				p.off[id] = true
			}
		}
	})
	a.card(c.Key(p.key+"/list"), func() {
		ui.Column(c).Gap(4).Children(func() {
			for _, id := range shown {
				on := !p.off[id]
				if ui.Checkbox(c.Key(id), &on, id).Changed() {
					p.off[id] = !on
				}
			}
			if len(shown) == 0 {
				a.muted(c, "No packages match.")
			}
		})
	})
}

func (a *app) installView(c *ui.Context) {
	if !a.needRepo(c) {
		return
	}
	s := a.scheme
	a.card(c, func() {
		row := func(k, v string) {
			ui.Row(c.Key(k)).Gap(12).PaddingY(4).Children(func() {
				ui.Text(c, k).FontSize(14).TextColor(s.OnSurfaceVariant).Width(160)
				ui.Text(c, v).FontSize(14).TextColor(s.OnSurface).Grow(1).Shrink(1)
			})
		}
		row("Flow", a.mode)
		row("Profile", a.profile)
		row("Secrets", map[bool]string{true: "on", false: "off"}[a.secrets])
		for i, p := range a.pkgs {
			row(p.title, fmt.Sprintf("%d of %d packages", len(a.chosen(i)), len(a.items(i))))
		}
		row("Source", a.sourceDir)
	})
	ready := a.mode == modeSecondary || a.keyOK
	if !ready {
		a.banner(c, true, "Import the GPG key first, or switch to the secondary flow.")
	}
	a.muted(c, "chezmoi init runs here. chezmoi apply opens in a console window, where its scripts may ask questions and UAC may prompt.")
	ui.Row(c).Children(func() { // a column would stretch the button
		if a.button(c, filled, "Install", a.busy != "" || !ready) {
			p := a.makePlan()
			a.step("Installing", func() error { return a.install(p) })
		}
	})
}

func main() {
	a := newApp()
	mygo.App.WhenReady(func() {
		a.win = mygo.NewWindow(mygo.WindowOptions{
			Title: appTitle, Width: 1000, Height: 760, MinWidth: 760, MinHeight: 560,
			TitleBarStyle: mygo.TitleBarHidden, TitleBarHeight: titleBarHeight, // the view draws an M3 title bar
			Content: ui.View(a.view),
		})
		go a.checkDeps()
	})
	if err := mygo.App.Run(); err != nil {
		log.Fatal(err)
	}
}
