// Command installer is a GUI for bootstrapping these dotfiles on Windows and
// Linux: it installs Git, Gpg4win and chezmoi (Windows; NixOS provides them on
// Linux), clones the repository, imports the GPG key, answers chezmoi's init
// prompts, picks the packages that run_once_00_windows-install would ask for
// with fzf (Windows), and runs chezmoi apply.
package main

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"runtime"
	"slices"
	"strings"
	"time"

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
	win     *mygo.Window // nil in tests
	goos    string       // runtime.GOOS; tests set it to check either platform
	linuxOS osInfo       // how Linux installs the prerequisites (prereqs.go)
	hasBrew bool         // Homebrew, for atomic distributions

	tab       int
	busy      string // title of the running step, "" when idle
	status    string
	statusErr bool

	scheme     *scheme // M3 colors of the frame (m3.go)
	schemeSeed ui.Color
	schemeDark bool
	lines      []string
	logState   ui.ListState
	logWin     *mygo.Window // the log in a window of its own, nil while it is in the main one
	logOpening bool         // logWin is being created
	copied     string       // key of the copyButton that copied last
	copiedAt   time.Time
	logFile    *os.File // every log line, also what chezmoi apply prints; nil in tests
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

	nixos       nixosCfg // the NixOS configuration to rebuild (nixos.go)
	nixosTested string   // flake that passed nixos-rebuild test: unlocks Switch

	atlas   atlasStatus // where the PC stands with Atlas, from its own records (atlas.go); Windows only
	edition string      // the Windows EditionID (Pro, Education, Core...), "" when unread
}

func newApp() *app {
	return newAppFor(runtime.GOOS)
}

func newAppFor(goos string) *app {
	home, _ := os.UserHomeDir()
	a := &app{
		goos:       goos,
		deps:       defaultDeps(goos),
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
	if goos == "linux" && runtime.GOOS == "linux" {
		a.linuxOS = readOS()
		a.nixos.dir = filepath.Join(home, "nixos-config")
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
	a.win.Update(func() {
		fn()
		if a.logWin != nil {
			a.logWin.Invalidate() // it shows the same log
		}
	})
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
		if a.logFile != nil {
			fmt.Fprintf(a.logFile, "[%s] %s\n", time.Now().Format("15:04:05"), s)
		}
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

// moduleOn is what the profile enables, as .chezmoi.toml.tmpl computes it:
// full turns every module on, minimal all but MinimalOff, custom asks.
func (a *app) moduleOn(m string) bool {
	switch a.profile {
	case "full":
		return true
	case "minimal":
		return !slices.Contains(a.repo.MinimalOff, m)
	}
	return a.modules[m]
}

// toCustom switches to the custom profile starting from what the current
// profile enables, so changing one module keeps the others.
func (a *app) toCustom() {
	if a.profile == "custom" {
		return
	}
	for _, m := range a.repo.Modules {
		a.modules[m] = a.moduleOn(m)
	}
	a.pkgVariant, a.profile = a.profile, "custom"
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

// page is a destination of the navigation rail.
type page struct{ id, icon, label, title, blurb string }

// logPage is the last destination of the rail on every OS: the whole log.
var logPage = page{"log", "terminal", "Log", "Log", "Everything the installer runs. Copy it, save it, or open it in a window of its own."}

// pages are the rail's destinations on this OS.
func (a *app) pages() []page { return append(a.stepPages(), logPage) }

// stepPages are the installation steps. Linux has no Packages page:
// NixOS/Home Manager installs its packages.
func (a *app) stepPages() []page {
	if a.goos != "windows" {
		var system []page // on NixOS the rebuild is what provides Git, GnuPG and chezmoi, so it goes first
		if a.linuxOS.nixos {
			system = []page{{"system", "settings", "System", "NixOS configuration", "Clones your NixOS configuration, then nixos-rebuild test and switch."}}
		}
		return append(system, []page{
			{"setup", "build", "Setup", "Prerequisites", "Installs the missing Git, GnuPG and chezmoi (on NixOS, says what to add), and clones the repository."},
			{"key", "key", "GPG key", "GPG key", "Choose how to handle the encrypted files."},
			{"profile", "tune", "Profile", "Install profile", "What chezmoi deploys. Answers chezmoi init's prompts."},
			{"install", "rocket_launch", "Install", "Install", "Review the choices and run chezmoi."},
		}...)
	}
	return []page{
		{"atlas", "desktop_windows", "Atlas", "Atlas", "Optional, and first: Atlas wants a fresh Windows 11. Downloads Atlas Manager and opens it."},
		{"setup", "build", "Setup", "Prerequisites", "Installs Git, Gpg4win and chezmoi with winget, and clones the repository."},
		{"key", "key", "GPG key", "GPG key", "Choose how to handle the encrypted files."},
		{"profile", "tune", "Profile", "Install profile", "What chezmoi deploys. Answers chezmoi init's prompts."},
		{"packages", "inventory_2", "Packages", "Packages", "What run_once_00_windows-install installs, instead of asking with fzf."},
		{"install", "rocket_launch", "Install", "Install", "Review the choices and run chezmoi."},
	}
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
			for i, p := range a.pages() {
				a.railItem(c, i, p.icon, p.label)
			}
		})
		// Content.
		ui.Column(c).Grow(1).Shrink(1).FillHeight().Padding(8, 24, 16, 8).Gap(16).Children(func() {
			st := a.pages()[a.tab]
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
			onLog := st.id == logPage.id
			switch {
			case !onLog:
				a.pageView(c, st)
			case a.logWin != nil:
				a.muted(c, "The log is in its own window. Close that window to bring it back here.")
			}
			if a.status != "" {
				a.banner(c, map[bool]bannerKind{true: failure, false: success}[a.statusErr], a.status)
			}
			if a.logWin == nil { // else the log is in its own window
				a.logView(c, false) // on the Log page it fills the rest of the window
			}
		})
	})
}

func (a *app) pageView(c *ui.Context, st page) {
	ui.Scroll(c.Key(a.tab)).Grow(1).Gap(16).Children(func() {
		switch st.id {
		case "system":
			a.systemView(c)
		case "atlas":
			a.atlasView(c)
		case "setup":
			a.prereqView(c)
		case "key":
			a.keyView(c)
		case "profile":
			a.profileView(c)
		case "packages":
			a.packagesView(c)
		case "install":
			a.installView(c)
		}
	})
}

// goTo opens a page by id.
func (a *app) goTo(id string) {
	for i, p := range a.pages() {
		if p.id == id {
			a.tab = i
		}
	}
}

const copiedFor = 2 * time.Second

// justCopied says whether the copy button called key copied a moment ago. The
// clipboard gives no sign of a copy, so the buttons show it themselves.
func (a *app) justCopied(key string) bool {
	return a.copied == key && time.Since(a.copiedAt) < copiedFor
}

// copyText puts text on the clipboard and starts the "copied" sign of key.
func (a *app) copyText(key, text string) {
	if a.win != nil {
		mygo.Clipboard.WriteText(text)
	}
	a.copied, a.copiedAt = key, time.Now()
	time.AfterFunc(copiedFor+50*time.Millisecond, func() { a.post(func() {}) }) // redraw: the sign goes
}

// copyButton is a text button that says "Copied" for two seconds.
func (a *app) copyButton(c *ui.Context, kind buttonKind, key, text string, disabled bool) {
	label := "Copy"
	if a.justCopied(key) {
		label = "Copied"
	}
	if a.button(c, kind, label, disabled) {
		a.copyText(key, text)
	}
}

// logText is the whole log on screen, for Copy.
func (a *app) logText() string { return strings.Join(a.lines, "\n") }

// saveLog copies the log file, which has every line with its time and not
// just the last maxLogLines, to a place the user chooses.
func (a *app) saveLog() {
	if a.win == nil {
		return
	}
	go func() {
		to, err := mygo.Dialog.Save(mygo.SaveDialogOptions{Parent: a.win, Title: "Save the log", DefaultPath: "dotfiles-installer.log"})
		if err != nil || to == "" {
			return
		}
		var data []byte
		if a.logFile != nil {
			data, err = os.ReadFile(a.logFile.Name())
		} else {
			a.sync(func() { data = []byte(a.logText() + "\n") })
		}
		if err == nil {
			err = os.WriteFile(to, data, 0o644)
		}
		if err != nil {
			a.logf("ERROR: saving the log: %v", err)
			return
		}
		a.logf("Log saved to %s", to)
	}()
}

// detachLog opens the log in a window of its own, which stays in view while
// the main window goes from page to page. Closing it puts the log back.
func (a *app) detachLog() {
	if a.win == nil || a.logWin != nil || a.logOpening {
		return
	}
	a.logOpening = true
	go func() {
		w := mygo.NewWindow(mygo.WindowOptions{
			Title: "Log - " + appTitle, Width: 900, Height: 600, MinWidth: 480, MinHeight: 240,
			Content: ui.View(a.logWindowView),
		})
		w.OnClosed(func() { a.post(func() { a.logWin, a.logOpening = nil, false }) })
		a.post(func() { a.logWin = w })
	}()
}

// logWindowView is the content of the log's own window.
func (a *app) logWindowView(c *ui.Context) {
	a.themed(c)
	ui.Column(c).Fill().Padding(16).Background(a.scheme.Surface).Children(func() {
		a.logView(c, true)
	})
}

// logView is the log panel. In the log's own window (own) it fills it and has
// copy and save; in the main window it also expands and opens that window.
func (a *app) logView(c *ui.Context, own bool) {
	s := a.scheme
	box := ui.Column(c).Background(s.SurfaceContainer).Radius(16).Padding(12, 16).Gap(8)
	onLog := a.pages()[a.tab].id == logPage.id
	if onLog || own {
		box = box.Grow(1) // on the Log page, and in its own window, it takes the rest
	} else {
		box = box.Height(220)
	}
	box.Children(func() {
		ui.Row(c).Gap(8).AlignItems(ui.Center).Children(func() {
			ui.Icon(c, icons["terminal"]).FontSize(18).TextColor(s.OnSurfaceVariant)
			ui.Text(c, "Log").FontSize(14).FontWeight(500).TextColor(s.OnSurfaceVariant).Grow(1)
			empty := len(a.lines) == 0
			if a.justCopied("log") {
				a.iconButton(c, "check", "Copied", false)
			} else if a.iconButton(c, "content_copy", "Copy", empty) {
				a.copyText("log", a.logText())
			}
			if a.iconButton(c, "save", "Save the log", empty) {
				a.saveLog()
			}
			if own {
				return
			}
			if !onLog && a.iconButton(c, "open_in_full", "Expand", false) {
				a.goTo(logPage.id)
			}
			if a.iconButton(c, "open_in_new", "Open the log in its own window", false) {
				a.detachLog()
			}
		})
		ui.List(c, &a.logState, len(a.lines), func(i int) {
			ui.Text(c, a.lines[i]).FontSize(12).TextColor(s.OnSurfaceVariant)
		}).Grow(1).Selectable().Children(func() {
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
		a.banner(c, info, "Run Setup first: the choices here come from the cloned repository.")
	}
	return a.repoOK
}

// missingHow says how Setup gets a missing tool on Linux.
func (a *app) missingHow(d dep, p prereqPlan) string {
	switch {
	case d.WingetID != "":
		return "Missing. winget: " + d.WingetID
	case d.Exe == "chezmoi" && p.chezmoi:
		return "Missing. Downloads chezmoi's static build into ~/.local/bin, no root needed."
	case d.Exe != "chezmoi" && p.cmd != nil:
		return "Missing. Installs with " + p.cmd[0] + " " + p.cmd[1] + "; the system asks for your password."
	case a.linuxOS.nixos:
		return "Missing. Add it to your NixOS/Home Manager configuration (below)."
	}
	return "Missing. See below."
}

func (a *app) prereqView(c *ui.Context) {
	p := a.prereqPlan()
	if a.goos == "windows" {
		p = prereqPlan{}
	}
	a.card(c, func() {
		for _, d := range a.deps {
			body := d.Path
			if d.Path == "" {
				body = a.missingHow(d, p)
			}
			a.listItem(c, d.Path != "", d.Name, body)
		}
		repo := a.sourceDir
		if !a.repoOK {
			repo = "Not cloned yet: " + a.sourceDir
		}
		a.listItem(c, a.repoOK, "Repository", repo)
	})
	if p.manual != "" {
		a.card(c, func() {
			a.sectionTitle(c, "Install by hand")
			ui.Text(c, p.manual).FontSize(14).Selectable().TextColor(a.scheme.OnSurfaceVariant)
			if a.win != nil {
				ui.Row(c).Children(func() {
					a.copyButton(c, tonal, "manual", p.manual, false)
				})
			}
		})
	}
	ui.Row(c).Gap(8).Children(func() {
		label := "Install missing tools and clone"
		if a.goos != "windows" && p.cmd == nil && !p.chezmoi {
			label = "Clone the repository"
		}
		if a.button(c, filled, label, a.busy != "") {
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
		a.banner(c, info, "chezmoi apply runs with --exclude=encrypted. Configure Git and SSH for this machine yourself.")
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
		full, minimal := "Every module and the full package lists.", "CLI, shell and the Aether desktop."
		if a.goos != "windows" {
			full, minimal = "Every module for Linux.", "CLI and shell configs."
		}
		for _, p := range []struct{ id, body string }{
			{"full", full},
			{"minimal", minimal + " Turns off " + strings.Join(a.repo.MinimalOff, ", ") + "."},
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
				if a.goos == "windows" {
					a.muted(c, "Owner only: fetches API keys from Bitwarden.")
				} else {
					// Its script picks secrets with fzf and Bitwarden asks for the login: it
					// needs a terminal, which a desktop launch does not give it.
					a.muted(c, "Owner only. On Linux it needs a terminal: use install.sh.")
				}
			})
			if a.goos != "windows" {
				a.secrets = false
			}
			ui.Switch(c, &a.secrets).Label("Personal secrets").Disabled(a.goos != "windows")
		})
	})
	a.card(c, func() {
		n := 0
		for _, m := range a.repo.Modules {
			if a.moduleOn(m) {
				n++
			}
		}
		a.sectionTitle(c, fmt.Sprintf("Modules  %d/%d", n, len(a.repo.Modules)))
		if a.profile != "custom" {
			a.muted(c, "What "+a.profile+" enables. Changing one switches to custom and keeps the rest.")
		}
		ui.Row(c).Wrap().Gap(8).Children(func() {
			for _, m := range a.repo.Modules {
				was := a.moduleOn(m)
				on := was
				a.filterChip(c, &on, m)
				if on != was {
					a.toCustom()
					a.modules[m] = on
				}
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
		a.banner(c, info, "Package lists: "+a.variant()+", from the install profile. mise and the PowerShell modules are always installed.")
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
			b.Cursor(ui.CursorPointer)
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
		var off []string
		for _, m := range a.repo.Modules {
			if !a.moduleOn(m) {
				off = append(off, m)
			}
		}
		mods := fmt.Sprintf("%d of %d", len(a.repo.Modules)-len(off), len(a.repo.Modules))
		if len(off) > 0 {
			mods += ", off: " + strings.Join(off, ", ")
		}
		row("Modules", mods)
		if a.goos == "windows" {
			for i, p := range a.pkgs {
				row(p.title, fmt.Sprintf("%d of %d packages", len(a.chosen(i)), len(a.items(i))))
			}
		}
		row("Source", a.sourceDir)
	})
	ready := a.mode == modeSecondary || a.keyOK
	if !ready {
		a.banner(c, info, "Import the GPG key first, or switch to the secondary flow.")
	}
	switch {
	case a.secrets:
		a.banner(c, info, "chezmoi apply opens in a console window: the secrets script asks for your Bitwarden login there. UAC may prompt.")
	case a.goos == "windows":
		a.banner(c, info, "chezmoi runs here: its output goes to the log below and to "+a.logPath()+". UAC may prompt for the elevated installs.")
	default:
		a.banner(c, info, "chezmoi runs here: its output goes to the log below and to "+a.logPath()+".")
	}
	ui.Row(c).Children(func() { // a column would stretch the button
		if a.button(c, filled, "Install", a.busy != "" || !ready) {
			p := a.makePlan()
			a.step("Installing", func() error { return a.install(p) })
		}
	})
}

func (a *app) logPath() string {
	if a.logFile == nil {
		return "a .log file"
	}
	return a.logFile.Name()
}

func main() {
	a := newApp()
	logName := filepath.Join(os.TempDir(), "dotfiles-installer-"+time.Now().Format("20060102-150405")+".log")
	if f, err := os.Create(logName); err == nil {
		a.logFile = f
		defer f.Close()
	} else {
		log.Printf("log file: %v", err) // the GUI log still works
	}
	mygo.App.WhenReady(func() {
		a.win = mygo.NewWindow(mygo.WindowOptions{
			Title: appTitle, Width: 1000, Height: 760, MinWidth: 760, MinHeight: 560,
			TitleBarStyle: mygo.TitleBarHidden, TitleBarHeight: titleBarHeight, // the view draws an M3 title bar
			Content: ui.View(a.view),
		})
		a.win.OnClosed(func() {
			if a.logWin != nil {
				a.logWin.Close() // the app ends with the main window
			}
		})
		a.logf("Log file: %s", a.logPath())
		go a.checkDeps()
		go a.checkAtlas(true)
	})
	if err := mygo.App.Run(); err != nil {
		log.Fatal(err)
	}
}
