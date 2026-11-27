package main

import (
	"os"
	"os/exec"
	"strings"
	"syscall"

	"golang.org/x/sys/windows"
	"golang.org/x/sys/windows/registry"
)

// hideWindow keeps console tools (winget, git, gpg) from flashing a window;
// their output goes to the GUI log instead.
func hideWindow(cmd *exec.Cmd) {
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true, CreationFlags: windows.CREATE_NO_WINDOW}
}

// newConsole gives a command a console window of its own, for chezmoi apply,
// whose scripts ask questions.
func newConsole(cmd *exec.Cmd) {
	cmd.SysProcAttr = &syscall.SysProcAttr{CreationFlags: windows.CREATE_NEW_CONSOLE}
}

// refreshPath reloads PATH from the registry, so tools winget just installed
// are found without restarting the installer.
func refreshPath() {
	var parts []string
	for _, k := range []struct {
		root registry.Key
		path string
	}{
		{registry.LOCAL_MACHINE, `SYSTEM\CurrentControlSet\Control\Session Manager\Environment`},
		{registry.CURRENT_USER, `Environment`},
	} {
		key, err := registry.OpenKey(k.root, k.path, registry.QUERY_VALUE)
		if err != nil {
			continue
		}
		if v, _, err := key.GetStringValue("Path"); err == nil {
			if exp, err := registry.ExpandString(v); err == nil {
				v = exp
			}
			parts = append(parts, v)
		}
		key.Close()
	}
	if len(parts) > 0 {
		os.Setenv("PATH", strings.Join(parts, ";"))
	}
}
