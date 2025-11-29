// repos is a tool to manage local git repos.
package main

import (
	_ "embed"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"slices"
	"strings"

	"go.seankhliao.com/mono/ycli"
)

func main() {
	conf := new(CommonConfig)
	ycli.OSExec(ycli.NewGroup(
		"repos",
		"tool for managing git repos",
		func(fs *flag.FlagSet) {
			fs.Func("eval-file", "path to a file to output commands to eval", func(s string) error {
				var err error
				conf.eval, err = os.OpenFile(s, os.O_RDWR, 0o644)
				return err
			})
		},
		cmdSync(),
		cmdLast(conf),
		cmdNew(conf),
		cmdClean(),
		cmdConfig(conf),
	))
}

type CommonConfig struct {
	// evalFile string
	eval *os.File
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
