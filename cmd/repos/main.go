// repos is a tool to manage local git repos.
package main

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
	"slices"
	"strings"

	"github.com/schollz/progressbar/v3"
	"go.seankhliao.com/mono/ycli"
)

func main() {
	ycli.OSExec(ycli.NewGroup(
		"repos",
		"tool for managing git repos",
		nil,
		cmdSync(),
		cmdSyncGithub(),
		cmdLast(),
		cmdNew(),
		cmdClean(),
	))
}

func progress(stderr io.Writer, n int, desc string) (<-chan struct{}, *progressbar.ProgressBar) {
	done := make(chan struct{}, 1)
	bar := progressbar.NewOptions(n,
		progressbar.OptionSetWriter(stderr),
		progressbar.OptionEnableColorCodes(true),
		progressbar.OptionSetPredictTime(false),
		progressbar.OptionShowCount(),
		progressbar.OptionFullWidth(),
		progressbar.OptionSetDescription(desc),
		progressbar.OptionSetTheme(progressbar.Theme{
			Saucer:        "[green]=[reset]",
			SaucerHead:    "[green]>[reset]",
			SaucerPadding: " ",
			BarStart:      "[",
			BarEnd:        "]",
		}),
		progressbar.OptionOnCompletion(func() {
			done <- struct{}{}
		}),
	)
	return done, bar
}

// tmpRepos returns direntries of temporary repos in sorted order
func tmpRepos() (string, []os.DirEntry, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return "", nil, fmt.Errorf("get home directory: %w", err)
	}
	tmpDir := filepath.Join(homeDir, "tmp")
	des, err := os.ReadDir(tmpDir)
	if err != nil {
		return "", nil, fmt.Errorf("read tmp directory: %w", err)
	}
	var out []os.DirEntry
	for i := range des {
		if strings.HasPrefix(des[i].Name(), "testrepo") {
			out = append(out, des[i])
		}
	}
	slices.SortFunc(out, func(a, b os.DirEntry) int {
		return strings.Compare(a.Name(), b.Name())
	})
	return tmpDir, out, nil
}
