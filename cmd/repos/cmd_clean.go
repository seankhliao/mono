package main

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
	"text/tabwriter"

	"go.seankhliao.com/mono/ycli"
)

func cmdClean() ycli.Command {
	return ycli.New(
		"clean",
		"clean up temporary repositories",
		nil,
		func(stdout, _ io.Writer) error {
			tmpDir, repos, err := tmpRepos()
			if err != nil {
				return fmt.Errorf("repos clean: %w", err)
			}
			if len(repos) == 0 {
				fmt.Fprintln(stdout, "repos clean: no repos to remove")
				return nil
			}

			done, bar := progress(stdout, len(repos), "Removing repositories")

			type repoError struct {
				name string
				err  error
			}

			var errs []repoError

			for _, r := range repos {
				bar.Describe(fmt.Sprintf("Removing %s", r.Name()))
				repoPath := filepath.Join(tmpDir, r.Name())
				err := os.RemoveAll(repoPath)
				if err != nil {
					errs = append(errs, repoError{r.Name(), err})
				}
				bar.Add(1)
			}

			<-done

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
		},
	)
}
