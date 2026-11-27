//go:build !windows

package main

import (
	"errors"
	"os"
	"os/exec"
)

// The installer targets Windows; these stand-ins let the view and its tests
// build and run on Linux.
func hideWindow(*exec.Cmd)   {}
func refreshPath()           {}
func windowsEdition() string { return "" }

// runConsole runs args in this terminal, the closest thing to a console of
// its own.
func runConsole(args, env []string) (int, error) {
	cmd := exec.Command(args[0], args[1:]...)
	cmd.Env = env
	cmd.Stdin, cmd.Stdout, cmd.Stderr = os.Stdin, os.Stdout, os.Stderr
	err := cmd.Run()
	var exit *exec.ExitError
	if errors.As(err, &exit) {
		return exit.ExitCode(), nil
	}
	return 0, err
}
