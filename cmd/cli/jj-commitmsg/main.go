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

	"go.seankhliao.com/mono/run"
)

func main() {
	run.OSExec(run.Func("jj-commitmsg", "generate a commit message prefix based on changed files", f))
}

func f(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	rootDirs, err := runcmd(ctx, "jj", "workspace", "root")
	if err != nil || len(rootDirs) != 1 {
		return fmt.Errorf("find workspace root: %v, %w", rootDirs, err)
	}
	os.Chdir(rootDirs[0])
	diffFiles, err := runcmd(ctx, "jj", "diff", "--name-only")
	if err != nil {
		return fmt.Errorf("find changed files: %w", err)
	} else if len(diffFiles) == 0 {
		return fmt.Errorf("no changed files")
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
	return nil
}

func runcmd(ctx context.Context, cmd string, args ...string) ([]string, error) {
	b, err := exec.CommandContext(ctx, cmd, args...).Output()
	if err != nil {
		return nil, fmt.Errorf("exec %v %v: %w", cmd, args, err)
	}
	lines := strings.FieldsFunc(string(b), func(r rune) bool {
		return r == '\n'
	})
	return lines, nil
}
