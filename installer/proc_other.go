//go:build !windows

package main

import "os/exec"

// The installer targets Windows; these stubs let the view and its tests build
// and run on Linux.
func hideWindow(*exec.Cmd) {}
func newConsole(*exec.Cmd) {}
func refreshPath()         {}
