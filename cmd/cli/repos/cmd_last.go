package main

import (
	"context"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"os"
	"path/filepath"
)

type lastCmd struct {
	evalFile string
}

func (c *lastCmd) Flags(fset *flag.FlagSet) error {
	fset.StringVar(&c.evalFile, "eval-file", "", "path to a file to output commands to eval")
	return nil
}

func (c *lastCmd) Run(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	tmpDir, repos, err := tmpRepos()
	if err != nil {
		return fmt.Errorf("repos last: %w", err)
	} else if len(repos) == 0 {
		return fmt.Errorf("repos last: no temporary directories")
	}

	repoName := repos[len(repos)-1].Name()

	var eval io.Writer = io.Discard
	if c.evalFile != "" {
		f, err := os.OpenFile(c.evalFile, os.O_RDWR|os.O_CREATE|os.O_TRUNC, 0o644)
		if err != nil {
			return fmt.Errorf("open eval file: %w", err)
		}
		defer f.Close()
		eval = f
	}

	fmt.Fprintf(eval, "cd %s\n", filepath.Join(tmpDir, repoName))
	return nil
}
