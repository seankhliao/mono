package main

import (
	"context"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"os"
	"path/filepath"
	"text/tabwriter"
	"time"

	"github.com/briandowns/spinner"
)

type cleanCmd struct{}

func (c *cleanCmd) Flags(fset *flag.FlagSet, args **[]string) error { return nil }

func (c *cleanCmd) Run(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	tmpDir, repos, err := tmpRepos()
	if err != nil {
		return fmt.Errorf("repos clean: %w", err)
	}
	if len(repos) == 0 {
		fmt.Fprintln(stdout, "repos clean: no repos to remove")
		return nil
	}

	spin := spinner.New(spinner.CharSets[39], 300*time.Millisecond, spinner.WithWriter(stdout))
	spin.Start()

	type repoError struct {
		name string
		err  error
	}

	var errs []repoError

	for _, r := range repos {
		spin.Suffix = fmt.Sprintf("Removing %s", r.Name())
		repoPath := filepath.Join(tmpDir, r.Name())
		err := os.RemoveAll(repoPath)
		if err != nil {
			errs = append(errs, repoError{r.Name(), err})
		}
	}

	spin.Stop()
	fmt.Fprintln(stdout)
	fmt.Fprintf(stdout, "Removed %d repos\n\n", len(repos)-len(errs))

	if len(errs) > 0 {
		fmt.Fprintln(stdout, "Error removing repos:")
		w := tabwriter.NewWriter(stdout, 1, 8, 1, ' ', 0)
		for _, err := range errs {
			fmt.Fprintf(w, "%s\t%v\n", err.name, err.err)
		}
		w.Flush()
	}
	return nil
}
