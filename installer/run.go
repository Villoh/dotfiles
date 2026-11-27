package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"runtime"
	"strings"
)

const repoURL = "https://github.com/Villoh/dotfiles"

// selectionEnv names the file with the GUI's package choices, which
// run_once_00_windows-install reads instead of asking with fzf.
const selectionEnv = "DOTFILES_PACKAGE_SELECTION"

type dep struct {
	Name, Exe, WingetID string // WingetID is "" on Linux: NixOS provides the tools
	Path                string // resolved executable, "" while missing
}

func defaultDeps(goos string) []dep {
	if goos != "windows" {
		return []dep{{Name: "Git", Exe: "git"}, {Name: "GnuPG", Exe: "gpg"}, {Name: "chezmoi", Exe: "chezmoi"}}
	}
	return []dep{
		{Name: "Git", Exe: "git", WingetID: "Git.Git"},
		{Name: "GnuPG (Gpg4win)", Exe: "gpg", WingetID: "GnuPG.Gpg4win"},
		{Name: "chezmoi", Exe: "chezmoi", WingetID: "twpayne.chezmoi"},
	}
}

// findExe finds a tool on PATH, and gpg where Gpg4win puts it, which is the
// path .chezmoi.toml.tmpl configures for chezmoi.
func findExe(name string) string {
	if name == "gpg" {
		for _, p := range []string{`C:\Program Files\GnuPG\bin\gpg.exe`, `C:\Program Files (x86)\GnuPG\bin\gpg.exe`} {
			if _, err := os.Stat(p); err == nil {
				return p
			}
		}
	}
	p, _ := exec.LookPath(name)
	return p
}

// ansiRe matches the color and cursor sequences tools print.
var ansiRe = regexp.MustCompile(`\x1b\[[0-9;?]*[A-Za-z]`)

// lineWriter sends what a command prints to the log, line by line, without
// ANSI sequences; winget redraws its progress with \r, which also ends a line.
type lineWriter struct {
	log func(string)
	buf []byte
}

func (w *lineWriter) Write(p []byte) (int, error) {
	w.buf = append(w.buf, p...)
	for {
		i := bytes.IndexAny(w.buf, "\r\n")
		if i < 0 {
			return len(p), nil
		}
		if line := strings.TrimSpace(ansiRe.ReplaceAllString(string(w.buf[:i]), "")); line != "" {
			w.log(line)
		}
		w.buf = w.buf[i+1:]
	}
}

func (w *lineWriter) Flush() {
	if line := strings.TrimSpace(ansiRe.ReplaceAllString(string(w.buf), "")); line != "" {
		w.log(line)
	}
	w.buf = nil
}

// run runs a console tool hidden, its output in the log. quiet drops stdout,
// for chezmoi diff, whose output is the whole diff.
func (a *app) run(quiet bool, name string, args ...string) error {
	a.logf("> %s %s", name, strings.Join(args, " "))
	cmd := exec.Command(name, args...)
	hideWindow(cmd)
	w := &lineWriter{log: a.logLine}
	cmd.Stdout, cmd.Stderr = w, w
	if quiet {
		cmd.Stdout = io.Discard
	}
	err := cmd.Run()
	w.Flush()
	if err != nil {
		return fmt.Errorf("%s: %w", name, err)
	}
	return nil
}

func (a *app) output(name string, args ...string) (string, error) {
	cmd := exec.Command(name, args...)
	hideWindow(cmd)
	out, err := cmd.Output()
	return strings.TrimSpace(string(out)), err
}

// step runs fn off the main thread with the buttons disabled, and logs its error.
func (a *app) step(title string, fn func() error) {
	if a.busy != "" {
		return
	}
	a.busy, a.status = title, ""
	go func() {
		err := fn()
		a.post(func() {
			a.busy = ""
			if err != nil {
				a.logf("ERROR: %v", err)
				a.status, a.statusErr = title+" failed: "+err.Error(), true
			}
		})
	}()
}

func (a *app) checkDeps() {
	deps := defaultDeps(a.goos)
	hasBrew := false
	if a.goos != "windows" {
		// chezmoi may sit in ~/.local/bin, which a desktop launch's PATH can lack.
		if dir, err := userBin(); err == nil {
			addToPath(dir)
		}
		_, err := exec.LookPath("brew")
		hasBrew = err == nil
	}
	for i := range deps {
		deps[i].Path = findExe(deps[i].Exe)
	}
	src := a.sourceDir
	if deps[2].Path != "" {
		if s, err := a.output(deps[2].Path, "source-path"); err == nil && s != "" {
			src = s
		}
	}
	info, repoErr := loadRepo(src, a.goos)
	a.post(func() {
		a.deps, a.sourceDir, a.hasBrew = deps, src, hasBrew
		if repoErr == nil {
			a.setRepo(info)
		}
	})
	if deps[1].Path != "" && repoErr == nil {
		a.checkKey()
	}
}

func (a *app) depPath(exe string) string {
	for _, d := range a.snapshotDeps() {
		if d.Exe == exe {
			return d.Path
		}
	}
	return ""
}

func (a *app) snapshotDeps() []dep {
	var deps []dep
	a.sync(func() { deps = append(deps, a.deps...) })
	return deps
}

// prereqPlan is how Linux gets the missing tools (prereqs.go), for the view
// and for prepare. Main thread.
func (a *app) prereqPlan() prereqPlan {
	var missing []string
	for _, d := range a.deps {
		if d.Path == "" {
			missing = append(missing, d.Exe)
		}
	}
	return planPrereqs(a.linuxOS, missing, runtime.GOARCH, a.hasBrew, "pkexec")
}

// installLinuxPrereqs does what it can of the plan, then reports what is
// left for the user.
func (a *app) installLinuxPrereqs() error {
	var p prereqPlan
	a.sync(func() { p = a.prereqPlan() })
	if p.cmd != nil {
		a.logf("Installing git/gnupg; the system asks for your password.")
		if err := a.run(false, p.cmd[0], p.cmd[1:]...); err != nil {
			return err
		}
	}
	if p.chezmoi {
		path, err := installChezmoi(chezmoiURL, chezmoiSHA256)
		if err != nil {
			return err
		}
		a.logf("Installed chezmoi into %s (checked SHA-256)", path)
	}
	if p.manual != "" {
		a.checkDeps()
		return errors.New(p.manual)
	}
	return nil
}

// prepare installs the missing tools (winget on Windows, installLinuxPrereqs
// on Linux) and clones the repository, whose files the next steps read.
func (a *app) prepare() error {
	if a.goos != "windows" {
		if err := a.installLinuxPrereqs(); err != nil {
			return err
		}
	}
	for _, d := range a.snapshotDeps() {
		if d.Path != "" || d.WingetID == "" {
			continue
		}
		if err := a.run(false, "winget", "install", "-e", "--id", d.WingetID,
			"--accept-package-agreements", "--accept-source-agreements", "--silent"); err != nil {
			return err
		}
	}
	refreshPath()
	a.checkDeps()
	for _, d := range a.snapshotDeps() {
		if d.Path == "" {
			return fmt.Errorf("%s still not found after installing it; open a new terminal and run the installer again", d.Name)
		}
	}
	var src string
	a.sync(func() { src = a.sourceDir })
	if _, err := os.Stat(filepath.Join(src, ".chezmoi.toml.tmpl")); err != nil {
		if entries, _ := os.ReadDir(src); len(entries) > 0 {
			return fmt.Errorf("%s exists but is not this repository; move it away first", src)
		}
		if err := a.run(false, a.depPath("git"), "clone", "--recurse-submodules", repoURL, src); err != nil {
			return err
		}
	} else {
		a.logf("Repository already at %s", src)
	}
	info, err := loadRepo(src, a.goos)
	if err != nil {
		return err
	}
	a.post(func() { a.setRepo(info); a.goTo("key") })
	a.checkKey()
	return nil
}

func (a *app) checkKey() {
	var recipient string
	a.sync(func() { recipient = a.repo.Recipient })
	gpg := a.depPath("gpg")
	ok := false
	if gpg != "" && recipient != "" {
		_, err := a.output(gpg, "--list-secret-keys", "--keyid-format", "long", recipient)
		ok = err == nil
	}
	a.post(func() { a.keyOK = ok })
}

func (a *app) importKey(keyFile, trustFile string) error {
	gpg := a.depPath("gpg")
	if err := a.run(false, gpg, "--import", keyFile); err != nil {
		return err
	}
	if trustFile != "" {
		if err := a.run(false, gpg, "--import-ownertrust", trustFile); err != nil {
			return err
		}
	}
	a.checkKey()
	return nil
}

// seedAgent copies the plaintext GPG/SSH agent files before chezmoi can
// decrypt anything, as docs/install/bootstrap.md step 4 does.
func (a *app) seedAgent(src string) error {
	home, err := os.UserHomeDir()
	if err != nil {
		return err
	}
	gnupg := filepath.Join(home, ".gnupg")
	if a.goos == "windows" {
		gnupg = filepath.Join(os.Getenv("APPDATA"), "gnupg")
	} else if g := os.Getenv("GNUPGHOME"); g != "" {
		gnupg = g
	}
	ssh := filepath.Join(home, ".ssh")
	copies := [][2]string{
		{`private_dot_gnupg/gpg-agent.conf`, filepath.Join(gnupg, "gpg-agent.conf")},
		{`private_dot_gnupg/private_sshcontrol`, filepath.Join(gnupg, "sshcontrol")},
		{`dot_ssh/config`, filepath.Join(ssh, "config")},
		{`dot_ssh/id_personal.pub`, filepath.Join(ssh, "id_personal.pub")},
		{`dot_ssh/id_work.pub`, filepath.Join(ssh, "id_work.pub")},
	}
	for _, c := range copies {
		b, err := os.ReadFile(filepath.Join(src, filepath.FromSlash(c[0])))
		if err != nil {
			return err
		}
		if err := os.MkdirAll(filepath.Dir(c[1]), 0o700); err != nil {
			return err
		}
		if err := os.WriteFile(c[1], b, 0o600); err != nil {
			return err
		}
		a.logf("Copied %s -> %s", c[0], c[1])
	}
	if gpgconf := findExe("gpgconf"); gpgconf != "" {
		_ = a.run(false, gpgconf, "--kill", "gpg-agent") // fails when no agent runs yet
		return a.run(false, gpgconf, "--launch", "gpg-agent")
	}
	return nil
}

// plan is a frozen copy of the choices, taken on the main thread.
type plan struct {
	src, chezmoi string
	initArgs     []string
	personal     bool
	secrets      bool
	selection    map[string]any
}

func (a *app) makePlan() plan {
	p := plan{src: a.sourceDir, chezmoi: a.depPath("chezmoi"), personal: a.mode == modePersonal, secrets: a.secrets}
	p.initArgs = initArgs(a.repo, a.profile, a.secrets, a.modules)
	p.selection = a.selection()
	return p
}

// initArgs answers every prompt of .chezmoi.toml.tmpl, so chezmoi init needs
// no terminal.
func initArgs(r repoInfo, profile string, secrets bool, modules map[string]bool) []string {
	args := []string{"init", "--no-tty",
		"--promptChoice", r.ProfilePrompt + "=" + profile,
		"--promptBool", fmt.Sprintf("%s=%t", r.SecretsPrompt, secrets),
	}
	if profile == "custom" {
		for _, m := range r.Modules {
			args = append(args, "--promptBool", fmt.Sprintf(r.ModuleFormat+"=%t", m, modules[m]))
		}
	}
	return args
}

// applyScript runs chezmoi apply in its own console and keeps the console open
// afterwards, so its output, and any error, stays readable. Only the secrets
// script needs it: it asks for the Bitwarden login.
func applyScript(chezmoi string, personal bool) string {
	apply := "& '" + strings.ReplaceAll(chezmoi, "'", "''") + "' apply"
	if !personal {
		apply += " --exclude=encrypted"
	}
	return apply + `; $code = $LASTEXITCODE; Write-Host
if ($code -eq 0) { Write-Host 'chezmoi apply finished.' -ForegroundColor Green }
else { Write-Host "chezmoi apply failed (exit $code). The error is above." -ForegroundColor Red }
[void](Read-Host 'Press Enter to close'); exit $code`
}

// applyArgs runs chezmoi apply without a terminal: a question it would ask
// fails with a message in the log instead of waiting for an answer.
func applyArgs(personal bool) []string {
	args := []string{"apply", "--no-tty"}
	if !personal {
		args = append(args, "--exclude=encrypted")
	}
	return args
}

// install initializes chezmoi, checks decryption for the personal flow, and
// applies: hidden with its output in the log, or with secrets in a console of
// its own, where Bitwarden can ask for the login.
func (a *app) install(p plan) error {
	if p.chezmoi == "" {
		return errors.New("chezmoi not found; run step 1 first")
	}
	if err := a.run(false, p.chezmoi, p.initArgs...); err != nil {
		return err
	}
	if p.personal {
		if err := a.seedAgent(p.src); err != nil {
			return err
		}
		a.logf("Checking that chezmoi can decrypt the encrypted files...")
		if err := a.run(true, p.chezmoi, "diff", "--no-pager", "--exclude=scripts"); err != nil {
			return fmt.Errorf("chezmoi diff failed, so GnuPG cannot decrypt yet (key imported? agent running?): %w", err)
		}
	}
	sel, err := json.MarshalIndent(p.selection, "", "  ")
	if err != nil {
		return err
	}
	selFile := filepath.Join(os.TempDir(), "dotfiles-installer-selection.json")
	if err := os.WriteFile(selFile, sel, 0o644); err != nil {
		return err
	}
	if p.secrets {
		a.logf("Running chezmoi apply in a console window: the secrets script asks for the Bitwarden login there.")
		code, err := runConsole(
			[]string{"powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", applyScript(p.chezmoi, p.personal)},
			append(os.Environ(), selectionEnv+"="+selFile))
		if err != nil {
			return fmt.Errorf("starting chezmoi apply: %w", err)
		}
		if code != 0 {
			return fmt.Errorf("chezmoi apply exited with %d; its error is in the console window it opened", code)
		}
	} else {
		// The scripts chezmoi runs inherit it.
		if err := os.Setenv(selectionEnv, selFile); err != nil {
			return err
		}
		if err := a.run(false, p.chezmoi, applyArgs(p.personal)...); err != nil {
			return err
		}
	}
	a.post(func() {
		a.status, a.statusErr = "Done. Open a new terminal; run setup-gpg-ssh once for SSH through GPG.", false
	})
	a.logf("Install finished.")
	return nil
}
