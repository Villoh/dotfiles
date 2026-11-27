package main

// The Info page: what this installer is (version, build), what it pins, where
// it keeps things, and where it comes from. Everything on it is also in
// infoText, which the copy button puts on the clipboard for a bug report.

import (
	"fmt"
	"regexp"
	"runtime"
	"runtime/debug"
	"strings"

	"github.com/egoist/mygo"
	"github.com/egoist/mygo/ui"
)

// version is the installer's release, set when building with
// -ldflags "-X main.version=0.1.10" (installer-ci.yml). A build without it
// shows the commit it was built from, or "dev".
var version string

const (
	releasesURL = repoURL + "/releases"
	myGoURL     = "https://github.com/egoist/mygo"
	atlasURL    = "https://atlasos.net"
)

// installerVersion is the version to show, and the commit when it is known.
func installerVersion() (v, commit string) {
	if bi, ok := debug.ReadBuildInfo(); ok {
		for _, s := range bi.Settings {
			if s.Key == "vcs.revision" && len(s.Value) >= 7 {
				commit = s.Value[:7]
			}
		}
	}
	switch {
	case version != "":
		return version, commit
	case commit != "":
		return "dev-" + commit, commit
	}
	return "dev", ""
}

var chezmoiVersionRe = regexp.MustCompile(`/download/(v[^/]+)/`)

// infoRow is one line of the Info page.
type infoRow struct{ key, value string }

// infoSection is a titled group of rows.
type infoSection struct {
	title string
	rows  []infoRow
}

// infoSections is what the page shows. The PC-specific rows are the ones a
// bug report needs: OS, Windows edition, where the repository and the log are.
func (a *app) infoSections() []infoSection {
	v, commit := installerVersion()
	inst := infoSection{"Installer", []infoRow{{"Version", v}}}
	if commit != "" {
		inst.rows = append(inst.rows, infoRow{"Commit", commit})
	}
	inst.rows = append(inst.rows, infoRow{"Built with", runtime.Version() + " for " + runtime.GOOS + "/" + runtime.GOARCH})

	pins := infoSection{title: "Pinned versions"}
	if a.goos == "windows" {
		if p, err := atlasPinned(); err == nil {
			pins.rows = append(pins.rows, infoRow{"Atlas Manager", p.Version})
		}
		pins.rows = append(pins.rows, infoRow{"Git, Gpg4win, chezmoi", "the latest from winget"})
	} else if m := chezmoiVersionRe.FindStringSubmatch(chezmoiURL); m != nil {
		pins.rows = append(pins.rows, infoRow{"chezmoi (static build)", m[1]})
	}

	sys := infoSection{title: "This PC"}
	switch {
	case a.goos == "windows":
		sys.rows = append(sys.rows, infoRow{"Windows", orDash(a.edition)})
	case a.linuxOS.id != "":
		sys.rows = append(sys.rows, infoRow{"Linux", a.linuxOS.id})
	}
	sys.rows = append(sys.rows,
		infoRow{"Repository", a.sourceDir},
		infoRow{"Log file", orDash(a.logPath())})
	return []infoSection{inst, pins, sys}
}

func orDash(s string) string {
	if s == "" {
		return "-"
	}
	return s
}

// infoText is the Info page as plain text.
func (a *app) infoText() string {
	var b strings.Builder
	for _, s := range a.infoSections() {
		fmt.Fprintf(&b, "%s\n", s.title)
		for _, r := range s.rows {
			fmt.Fprintf(&b, "  %s: %s\n", r.key, r.value)
		}
	}
	return strings.TrimRight(b.String(), "\n")
}

// openLink opens url in the default browser, off the main thread.
func (a *app) openLink(url string) {
	if a.win == nil {
		return
	}
	go func() {
		if err := mygo.Shell.OpenExternal(url); err != nil {
			a.logf("ERROR: opening %s: %v", url, err)
		}
	}()
}

func (a *app) infoView(c *ui.Context) {
	s := a.scheme
	ui.Row(c).Gap(8).AlignItems(ui.Center).Children(func() {
		ui.Text(c, "Copy this page to put it in a bug report.").FontSize(14).TextColor(s.OnSurfaceVariant).Grow(1)
		if a.justCopied("info") {
			a.iconButton(c, "check", "Copied", false)
		} else if a.iconButton(c, "content_copy", "Copy this page", false) {
			a.copyText("info", a.infoText())
		}
	})
	for _, sec := range a.infoSections() {
		a.card(c, func() {
			a.sectionTitle(c, sec.title)
			for _, r := range sec.rows {
				ui.Row(c.Key(sec.title + r.key)).Gap(12).PaddingY(2).Children(func() {
					ui.Text(c, r.key).FontSize(14).TextColor(s.OnSurfaceVariant).Width(160)
					ui.Text(c, r.value).FontSize(14).TextColor(s.OnSurface).Grow(1).Shrink(1).Selectable()
				})
			}
		})
	}
	a.card(c, func() {
		a.sectionTitle(c, "Links")
		ui.Row(c).Gap(8).Children(func() {
			for _, l := range []struct{ label, url string }{
				{"Repository", repoURL}, {"Releases", releasesURL}, {"MyGo", myGoURL}, {"Atlas", atlasURL},
			} {
				if a.button(c, tonal, l.label, false) {
					a.openLink(l.url)
				}
			}
		})
	})
	a.card(c, func() {
		a.sectionTitle(c, "Licenses")
		a.muted(c, "The interface is built with MyGo (MIT). The icons are Material Symbols from google/material-design-icons (Apache License 2.0). The dependencies and their licenses are in installer/go.mod.")
	})
}
