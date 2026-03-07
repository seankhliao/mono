package main

import (
	"context"
	"fmt"
	"io"
	"io/fs"
	"path/filepath"

	"go.seankhliao.com/mono/cmdline"
)

func cmdLast(conf *CommonConfig) cmdline.Commander {
	return cmdline.CommandRun(
		"last",
		"switches to the newest temporary repository",
		func(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) int {
			tmpDir, repos, err := tmpRepos()
			if err != nil {
				fmt.Fprintf(stderr, "repos last: %v\n", err)
				return 1
			} else if len(repos) == 0 {
				fmt.Fprintln(stderr, "repos last: no temporary directories")
				return 1
			}

			repoName := repos[len(repos)-1].Name()
			fmt.Fprintf(conf.eval, "cd %s\n", filepath.Join(tmpDir, repoName))
			return 0
		},
	)
}
