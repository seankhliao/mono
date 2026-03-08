package main

import (
	"context"
	"fmt"
	"io"
	"io/fs"
	"path/filepath"

	"go.seankhliao.com/mono/run"
)

func cmdLast(conf *CommonConfig) run.Commander {
	return run.CommandRun(
		"last",
		"switches to the newest temporary repository",
		func(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
			tmpDir, repos, err := tmpRepos()
			if err != nil {
				return fmt.Errorf("repos last: %w", err)
			} else if len(repos) == 0 {
				return fmt.Errorf("repos last: no temporary directories")
			}

			repoName := repos[len(repos)-1].Name()
			fmt.Fprintf(conf.eval, "cd %s\n", filepath.Join(tmpDir, repoName))
			return nil
		},
	)
}
