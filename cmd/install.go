package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"runtime"
	"strings"
)

func check(err error) {
	if err != nil {
		fmt.Println("❌ Error:", err)
		os.Exit(1)
	}
}

func main() {
	home, err := os.UserHomeDir()
	check(err)

	// Installation paths
	prefix := filepath.Join(home, ".local")
	libDir := filepath.Join(prefix, "lib", "ToolGit")
	binDir := filepath.Join(prefix, "bin")

	// Create directories
	check(os.MkdirAll(libDir, 0755))
	check(os.MkdirAll(binDir, 0755))

	// Copy git_helpers.sh to libDir
	src := filepath.Join(".", "bin", "git_helpers.sh")
	dst := filepath.Join(libDir, "git_helpers.sh")
	data, err := ioutil.ReadFile(src)
	check(err)
	check(ioutil.WriteFile(dst, data, 0644))

	fmt.Println("📦 git_helpers.sh installed to:", dst)

	// Create wrappers for gh_* functions
	lines := strings.Split(string(data), "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if strings.HasPrefix(line, "gh_") && strings.Contains(line, "()") {
			fn := strings.Split(line, "(")[0]
			wrapperPath := filepath.Join(binDir, fn)

			var wrapperContent string
			if runtime.GOOS == "windows" {
				wrapperPath += ".bat"
				wrapperContent = fmt.Sprintf(`@echo off
bash -c "source '%s' && %s %%*"`, dst, fn)
			} else {
				wrapperContent = fmt.Sprintf(`#!/usr/bin/env bash
source '%s'
%s "$@"`, dst, fn)
			}

			check(ioutil.WriteFile(wrapperPath, []byte(wrapperContent), 0755))
			fmt.Println("🛠 Created wrapper:", wrapperPath)
		}
	}

	fmt.Println("✅ ToolGit installation complete!")
	fmt.Printf("💡 Make sure %s is in your PATH.\n", binDir)
	fmt.Println("💡 You can now run gh_* commands directly, e.g., gh_help")
}
