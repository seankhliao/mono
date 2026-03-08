package main

import (
	"context"
	"fmt"
	"io"
	"io/fs"
	"os"
	"os/exec"
	"path"
	"strings"

	run1 "go.seankhliao.com/mono/run"
)

func main() {
	run1.OSExec(run1.CommandRun(
		"jj-commitmsg",
		"generate a commit message prefix based on changed files",
		func(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) int {
			rootDirs, err := run(ctx, "jj", "workspace", "root")
			if err != nil || len(rootDirs) != 1 {
				fmt.Fprintln(stderr, "find workspace root", rootDirs, err)
				return 1
			}
			os.Chdir(rootDirs[0])
			diffFiles, err := run(ctx, "jj", "diff", "--name-only")
			if err != nil {
				fmt.Fprintln(stderr, "find changed files", err)
				return 1
			} else if len(diffFiles) == 0 {
				fmt.Fprintln(stderr, "no changed files")
				return 1
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
			fmt.Fprint(stdout, common)
			return 0
		}),
	)
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
