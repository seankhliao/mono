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

	"cuelang.org/go/cue"
	"cuelang.org/go/cue/cuecontext"
	"go.seankhliao.com/mono/ycli"
)

func main() {
	conf := new(CommonConfig)
	ycli.OSExec(ycli.NewGroup(
		"repos",
		"tool for managing git repos",
		func(fs *flag.FlagSet) {
			fs.StringVar(&conf.configFile, "config", "repos.cue", "path to config file")
			fs.Func("eval-file", "path to a file to output commands to eval", func(s string) error {
				var err error
				conf.eval, err = os.OpenFile(s, os.O_RDWR, 0o644)
				return err
			})
		},
		cmdSync(),
		cmdSyncGithub(conf),
		cmdLast(conf),
		cmdNew(conf),
		cmdClean(),
		cmdConfig(conf),
	))
}

//go:embed schema.cue
var schemaBytes []byte

type CommonConfig struct {
	configFile string
	configVal  cue.Value
	cueCtx     *cue.Context

	// evalFile string
	eval *os.File
}

func (c *CommonConfig) defaultConfig() (*cue.Context, cue.Value) {
	if c.cueCtx == nil {
		c.cueCtx = cuecontext.New()
		c.configVal = c.cueCtx.CompileBytes(schemaBytes)
	}
	return c.cueCtx, c.configVal
}

func (c *CommonConfig) resolvedConfig() (cue.Value, error) {
	c.defaultConfig()
	configBytes, err := os.ReadFile(c.configFile)
	if err != nil {
		return cue.Value{}, fmt.Errorf("repos: read config file: %w", err)
	}
	c.configVal = c.configVal.Unify(c.cueCtx.CompileBytes(configBytes))
	err = c.configVal.Validate()
	if err != nil {
		return cue.Value{}, fmt.Errorf("repos: validate config: %w", err)
	}
	return c.configVal, nil
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
