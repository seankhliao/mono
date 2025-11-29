// Command gosdkupdate keeps the latest patch version of each minor go version available
// via the golang.org/dl wrappers.
// It also updates gotip to the current tip.
package main

import (
	"bytes"
	"context"
	"debug/buildinfo"
	_ "embed"
	"flag"
	"fmt"
	"go/version"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"github.com/briandowns/spinner"
	"go.seankhliao.com/mono/cueconf"
	"go.seankhliao.com/mono/goreleases"
	"go.seankhliao.com/mono/ycli"
)

//go:embed schema.cue
var configSchema string

type Config struct {
	Go struct {
		Bootstrap string `json:"bootstrap"`
		Releases  int    `json:"releases"`
		Pre       bool   `json:"pre"`
		Tip       struct {
			Update bool `json:"update"`
		} `json:"tip"`
	}
	Tools struct {
		Update    bool `json:"update"`
		Overrides map[string]struct {
			Version string `json:"version"`
			Cgo     bool   `json:"cgo"`
		} `json:"overrides"`
	} `json:"tools"`
}

func main() {
	confDir, err := os.UserConfigDir()
	if err != nil {
		homeDir, err := os.UserHomeDir()
		if err != nil {
			fmt.Fprintln(os.Stderr, "get user home dir", err)
			os.Exit(1)
		}
		confDir = filepath.Join(homeDir, ".config")
	}
	confFile := filepath.Join(confDir, "gosdkupdate.cue")
	ycli.OSExec(ycli.New(
		"gosdkupdate",
		"keep up to date go toolchains",
		func(fs *flag.FlagSet) {
			fs.StringVar(&confFile, "config", confFile, "path to config file")
		},
		func(stdout, _ io.Writer) error {
			conf, err := cueconf.ForFile[Config](configSchema, "#GosdkupdateConfig", confFile, true)
			if err != nil {
				return fmt.Errorf("gosdkupdate: decode config: %w", err)
			}

			tmpDir, err := os.MkdirTemp("", "gosdkupdate.*")
			if err != nil {
				return fmt.Errorf("gosdkupdate: prepare temp dir: %w", err)
			}
			err = os.Chdir(tmpDir)
			if err != nil {
				return fmt.Errorf("gosdkupdate: switch to temp dir: %w", err)
			}

			err = updateGo(conf, stdout)
			if err != nil {
				return fmt.Errorf("gosdkupdate: update go installations: %w", err)
			}

			err = updateTools(conf, stdout)
			if err != nil {
				return fmt.Errorf("gosdkupdate: update tools: %w", err)
			}
			return nil
		},
	))
}

func updateGo(c Config, stdout io.Writer) error {
	ctx := context.Background()

	toUpdate := c.Go.Releases
	if c.Go.Tip.Update {
		toUpdate++
	}

	spin := spinner.New(spinner.CharSets[39], 100*time.Millisecond, spinner.WithWriter(stdout))
	spin.FinalMSG = fmt.Sprintf("%2d/%2d Go installations updated\n", toUpdate, toUpdate)
	spin.Start()
	defer spin.Stop()

	spin.Suffix = "checking for latest releases"

	baseEnv := os.Environ()
	baseEnv = append(baseEnv, "GOENV=off")
	gopath := os.Getenv("GOPATH")
	if gopath == "" {
		return fmt.Errorf("GOPATH not set in env")
	}
	gobin := filepath.Join(gopath, "bin")
	des, err := os.ReadDir(gobin)
	if err == nil {
		for _, de := range des {
			if strings.HasPrefix(de.Name(), "go1.") || de.Name() == "go" {
				os.Remove(filepath.Join(gobin, de.Name()))
			}
		}
	}

	if c.Go.Releases > 0 || c.Go.Pre {
		// find the current releases
		rels, err := goreleases.Releases(http.DefaultClient, ctx, "", true)
		if err != nil {
			return fmt.Errorf("get go releases: %w", err)
		}

		need := c.Go.Releases
		var toKeep []string
		var lastLang string
		for i, rel := range rels {
			if !rel.Stable {
				if i == 0 && c.Go.Pre {
					toKeep = append(toKeep, rel.Version)
				}
				continue
			}
			if need == 0 {
				break
			}
			lang := version.Lang(rel.Version)
			if lang != lastLang {
				lastLang = lang
				toKeep = append(toKeep, rel.Version)
				need--
			}
		}

		toUpdate = len(toKeep)
		if c.Go.Tip.Update {
			toUpdate++
		}
		spin.FinalMSG = fmt.Sprintf("%2d/%2d Go installations updated\n", toUpdate, toUpdate)

		for i, rel := range toKeep {
			spin.Suffix = fmt.Sprintf("%2d/%2d installing %s", i+1, toUpdate, rel)

			cmd := exec.CommandContext(ctx, c.Go.Bootstrap, "env", "GOROOT")
			cmd.Env = append(baseEnv,
				"GOTOOLCHAIN="+rel,
			)
			out, err := cmd.Output()
			if err != nil {
				return fmt.Errorf("download %s: %w\n%s", rel, err, out)
			}
			p := filepath.Join(string(bytes.TrimSpace(out)), "bin/go")
			np := filepath.Join(gobin, rel)
			err = os.Symlink(p, np)
			if err != nil {
				return fmt.Errorf("symlink %s => %s: %w", np, p, err)
			}
		}
	}

	if c.Go.Tip.Update {
		spin.Suffix = fmt.Sprintf("%2d/%2d installing tip", toUpdate, toUpdate)

		cmd := exec.CommandContext(ctx, c.Go.Bootstrap, "install", "golang.org/dl/gotip@latest")
		cmd.Env = baseEnv
		out, err := cmd.CombinedOutput()
		if err != nil {
			return fmt.Errorf("download gotip: %w\n%s", err, out)
		}

		gotip := filepath.Join(gobin, "gotip")
		cmd = exec.CommandContext(ctx, gotip, "download")
		cmd.Env = baseEnv
		out, err = cmd.CombinedOutput()
		if err != nil {
			return fmt.Errorf("gotip download: %w\n%s", err, out)
		}

		cmd = exec.CommandContext(ctx, gotip, "env", "GOROOT")
		cmd.Env = baseEnv
		out, err = cmd.CombinedOutput()
		if err != nil {
			return fmt.Errorf("gotip env GOROOT: %w\n%s", err, out)
		}
		p := filepath.Join(string(bytes.TrimSpace(out)), "bin/go")
		np := filepath.Join(gobin, "go")
		err = os.Symlink(p, np)
		if err != nil {
			return fmt.Errorf("symlink %s => %s: %w", np, p, err)
		}
	}

	return nil
}

func updateTools(c Config, stdout io.Writer) error {
	ctx := context.Background()

	spin := spinner.New(spinner.CharSets[39], 100*time.Millisecond, spinner.WithWriter(stdout))
	spin.Start()
	defer spin.Stop()

	gopath := os.Getenv("GOPATH")
	if gopath == "" {
		return fmt.Errorf("GOPATH not set in env")
	}
	gobin := filepath.Join(gopath, "bin")

	spin.Suffix = fmt.Sprintf("checking for tools in %s", gobin)

	var toUpdate []string
	var skipped []error

	des, err := os.ReadDir(gobin)
	if err != nil {
		return fmt.Errorf("list installed go tools: %w", err)
	}
	for _, de := range des {
		if de.Name() == "gotip" || de.Name() == "go" || strings.HasPrefix(de.Name(), "go1") {
			// shims we just installed
			continue
		}
		fp := filepath.Join(gobin, de.Name())
		bi, err := buildinfo.ReadFile(fp)
		if err != nil {
			skipped = append(skipped, fmt.Errorf("%s: %s", de.Name(), err))
			continue
		}
		toUpdate = append(toUpdate, bi.Path)
	}

	spin.FinalMSG = fmt.Sprintf("%d tools updated", len(toUpdate))

	var errs []error
	for i, tool := range toUpdate {
		spin.Suffix = fmt.Sprintf("%3d/%3d installing %s", i+1, len(toUpdate), tool)

		baseEnv := os.Environ()

		targetVer := "latest"
		override, ok := c.Tools.Overrides[tool]
		if ok {
			targetVer = override.Version
			if override.Cgo {
				var found bool
				for idx := range baseEnv {
					if strings.HasPrefix(baseEnv[i], "CGO_ENABLED=") {
						found = true
						baseEnv[idx] = "CGO_ENABLED=1"
						break
					}
				}
				if !found {
					baseEnv = append(baseEnv, "CGO_ENABLED=1")
				}
			}
		}

		cmd := exec.CommandContext(ctx, "go", "install", fmt.Sprintf("%s@%s", tool, targetVer))
		cmd.Env = baseEnv
		out, err := cmd.CombinedOutput()
		if err != nil {
			errs = append(errs, fmt.Errorf("%s: %w\n\t%s", tool, err, out))
		}
	}

	spin.Stop()

	fmt.Fprintln(stdout, "Updated:")
	for _, tool := range toUpdate {
		fmt.Fprintln(stdout, "\t", tool)
	}
	fmt.Fprintln(stdout, "Errored:")
	for _, err := range errs {
		fmt.Fprintln(stdout, "\t", err)
	}
	fmt.Fprintln(stdout, "Skipped:")
	for _, err := range skipped {
		fmt.Fprintln(stdout, "\t", err)
	}

	return nil
}
