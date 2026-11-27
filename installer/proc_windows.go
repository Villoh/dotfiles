package main

import (
	"os"
	"os/exec"
	"strings"
	"syscall"
	"unicode/utf16"
	"unsafe"

	"golang.org/x/sys/windows"
	"golang.org/x/sys/windows/registry"
)

// hideWindow keeps console tools (winget, git, gpg) from flashing a window;
// their output goes to the GUI log instead.
func hideWindow(cmd *exec.Cmd) {
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true, CreationFlags: windows.CREATE_NO_WINDOW}
}

// runConsole runs args in a console window of its own, for chezmoi apply,
// whose scripts ask questions, waits, and returns its exit code. os/exec
// cannot do this: it always hands the child std handles (NUL when unset), so
// the new console stays black and every read gets EOF. CreateProcess without
// STARTF_USESTDHANDLES lets the child use its console.
func runConsole(args, env []string) (int, error) {
	cmdline, err := windows.UTF16PtrFromString(windows.ComposeCommandLine(args))
	if err != nil {
		return 0, err
	}
	var block []uint16 // "k=v\0k=v\0\0"
	for _, kv := range env {
		block = append(block, utf16.Encode([]rune(kv))...)
		block = append(block, 0)
	}
	block = append(block, 0, 0)
	si := windows.StartupInfo{Cb: uint32(unsafe.Sizeof(windows.StartupInfo{}))}
	var pi windows.ProcessInformation
	if err := windows.CreateProcess(nil, cmdline, nil, nil, false,
		windows.CREATE_NEW_CONSOLE|windows.CREATE_UNICODE_ENVIRONMENT, &block[0], nil, &si, &pi); err != nil {
		return 0, err
	}
	defer windows.CloseHandle(pi.Process)
	defer windows.CloseHandle(pi.Thread)
	if _, err := windows.WaitForSingleObject(pi.Process, windows.INFINITE); err != nil {
		return 0, err
	}
	var code uint32
	if err := windows.GetExitCodeProcess(pi.Process, &code); err != nil {
		return 0, err
	}
	return int(code), nil
}

// windowsEdition is the EditionID of this Windows (Pro, Education, Core...),
// "" when it cannot be read.
func windowsEdition() string {
	key, err := registry.OpenKey(registry.LOCAL_MACHINE, `SOFTWARE\Microsoft\Windows NT\CurrentVersion`, registry.QUERY_VALUE)
	if err != nil {
		return ""
	}
	defer key.Close()
	v, _, _ := key.GetStringValue("EditionID")
	return v
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
