package main

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"path"
	"strings"
)

func main() {
	ctx := context.Background()
	rootDirs, err := run(ctx, "jj", "workspace", "root")
	if err != nil || len(rootDirs) != 1 {
		fmt.Fprintln(os.Stderr, "find workspace root", rootDirs, err)
		os.Exit(1)
	}
	os.Chdir(rootDirs[0])
	diffFiles, err := run(ctx, "jj", "diff", "--name-only")
	if err != nil {
		fmt.Fprintln(os.Stderr, "find changed files", err)
		os.Exit(1)
	} else if len(diffFiles) == 0 {
		fmt.Fprintln(os.Stderr, "no changed files")
		os.Exit(1)
	}

	common := diffFiles[0]
findCommon:
	for {
		common = path.Dir(common)
		if common == "." {
			common = "all"
			break findCommon
		}
		allMatch := true
		for _, file := range diffFiles {
			if !strings.HasPrefix(file, common) {
				allMatch = false
			}
		}
		if allMatch {
			break findCommon
		}
	}
	fmt.Print(common)
}

func run(ctx context.Context, cmd string, args ...string) ([]string, error) {
	b, err := exec.CommandContext(ctx, cmd, args...).Output()
	if err != nil {
		return nil, fmt.Errorf("exec %v %v: %w", cmd, args, err)
	}
	lines := strings.FieldsFunc(string(b), func(r rune) bool {
		return r == '\n'
	})
	return lines, nil
}
