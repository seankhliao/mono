package main

import (
	"bytes"
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"sync"
	"text/tabwriter"
	"time"

	"github.com/briandowns/spinner"
	"go.seankhliao.com/mono/ycli"
)

func cmdSync() ycli.Command {
	var parallel int
	return ycli.New(
		"sync",
		"sync repositories with upstream origins",
		func(fs *flag.FlagSet) {
			fs.IntVar(&parallel, "parallel", 5, "max parallel git operations")
		},
		func(stdout, _ io.Writer) error {
			err := runSync(stdout, parallel)
			if err != nil {
				return fmt.Errorf("repos sync: %w", err)
			}
			return nil
		},
	)
}

func runSync(stdout io.Writer, parallel int) error {
	baseDir := "."
	des, err := os.ReadDir(baseDir)
	if err != nil {
		return fmt.Errorf("sync: read %s: %w", baseDir, err)
	}
	dirs := make([]string, 0, len(des))
	for _, de := range des {
		if de.IsDir() {
			dirs = append(dirs, filepath.Join(baseDir, de.Name()))
		}
	}

	spin := spinner.New(spinner.CharSets[39], 300*time.Millisecond)
	spin.Start()

	results := make(chan syncResult, len(dirs))
	parallelToken := make(chan struct{}, parallel)
	go func() {
		var wg sync.WaitGroup

		for _, repo := range dirs {
			parallelToken <- struct{}{}
			wg.Add(1)
			go func() {
				defer func() { <-parallelToken }()
				defer wg.Done()
				results <- syncRepo(repo)
			}()
		}

		wg.Wait()
		close(results)
	}()

	var errs []syncResult
	for res := range results {
		if res.err == nil {
			spin.Suffix = fmt.Sprintf("Synced %s to %s", filepath.Base(res.dir), res.newRef)
		} else {
			spin.Suffix = fmt.Sprintf("Error syncing %s", filepath.Base(res.dir))
			errs = append(errs, res)
		}
	}

	spin.Stop()
	fmt.Fprintln(stdout)
	fmt.Fprintf(stdout, "Synced %d repos\n\n", len(dirs)-len(errs))

	if len(errs) > 0 {
		fmt.Fprintln(stdout, "Errors with the following repos:")
		w := tabwriter.NewWriter(stdout, 0, 8, 1, ' ', 0)

		for _, res := range errs {
			fmt.Fprintf(w, "%s\t%v\n", res.dir, res.err)
		}
		w.Flush()
	}

	return nil
}

type syncResult struct {
	dir    string
	err    error
	oldRef string
	newRef string
}

func syncRepo(dir string) syncResult {
	res := syncResult{
		dir: filepath.Base(dir),
	}

	wd := filepath.Join(dir, "default")
	gitDir := filepath.Join(wd, ".git")
	_, err := os.Stat(gitDir)
	if err != nil {
		wd = dir
		gitDir = filepath.Join(wd, ".git")
		_, err = os.Stat(gitDir)
		if err != nil {
			res.err = fmt.Errorf("no git dir found")
			return res
		}
	}

	cmd := exec.Command("git", "rev-parse", "--short", "HEAD")
	cmd.Dir = wd
	out, err := cmd.CombinedOutput()
	if err != nil {
		res.err = fmt.Errorf("get old ref: %w", err)
		return res
	}
	res.oldRef = string(bytes.TrimSpace(out))

	// ensure we're on the default branch
	cmd = exec.Command("git", "rev-parse", "--abbrev-ref", "origin/HEAD")
	cmd.Dir = wd
	out, err = cmd.CombinedOutput()
	if err != nil {
		res.err = fmt.Errorf("get remote default branch: %w\n%s", err, out)
		return res
	}

	defaultBranch := path.Base(string(bytes.TrimSpace(out)))

	cmd = exec.Command("git", "checkout", defaultBranch)
	cmd.Dir = wd
	out, err = cmd.CombinedOutput()
	if err != nil {
		res.err = fmt.Errorf("switch to default branch: %w\n%s", err, out)
		return res
	}

	cmd = exec.Command("git", "fetch", "--tags", "--prune", "--prune-tags", "--force", "--jobs=10")
	cmd.Dir = wd
	out, err = cmd.CombinedOutput()
	if err != nil {
		res.err = fmt.Errorf("fetch: %w\n%s", err, out)
		return res
	}
	cmd = exec.Command("git", "merge", "--ff-only", "--autostash")
	cmd.Dir = wd
	out, err = cmd.CombinedOutput()
	if err != nil {
		res.err = fmt.Errorf("merge: %w\n%s", err, out)
		return res
	}

	cmd = exec.Command("git", "worktree", "prune")
	cmd.Dir = wd
	out, err = cmd.CombinedOutput()
	if err != nil {
		res.err = fmt.Errorf("prune worktrees: %w\n%s", err, out)
		return res
	}

	cmd = exec.Command("git", "rev-parse", "--short", "HEAD")
	cmd.Dir = wd
	out, err = cmd.CombinedOutput()
	if err != nil {
		res.err = fmt.Errorf("get new ref: %w\n%s", err, out)
		return res
	}
	res.newRef = string(bytes.TrimSpace(out))

	return res
}
