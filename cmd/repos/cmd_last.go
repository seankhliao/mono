package main

import (
	"fmt"
	"io"
	"path/filepath"

	"go.seankhliao.com/mono/ycli"
)

func cmdLast(conf *CommonConfig) ycli.Command {
	return ycli.New(
		"last",
		"switches to the newest temporary repository",
		nil,
		func(stdout, stderr io.Writer) error {
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
