// repos is a tool to manage local git repos.
package main

import (
	_ "embed"
	"fmt"
	"os"
	"path/filepath"
	"slices"
	"strings"

	"go.seankhliao.com/mono/run"
)

func main() {
	run.OSExec(run.Group(
		"repos",
		"tool for managing git repos",
		run.Simple("sync", "sync repositories with upstream origins", &Sync{}),
		run.Simple("last", "switches to the newest temporary repository", &Last{}),
		run.Simple("new", "creates a new repository", &New{}),
		run.Simple("clean", "clean up temporary repositories", &Clean{}),
		run.Simple("config", "print the config", &Wrapper{}),
	))
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
