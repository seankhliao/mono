// Command gosdkupdate keeps the latest patch version of each minor go version available
// via the golang.org/dl wrappers.
// It also updates gotip to the current tip.
package main

import (
	"bytes"
	"context"
	"debug/buildinfo"
	"flag"
	"fmt"
	"go/version"
	"io"
	"io/fs"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"github.com/briandowns/spinner"
	"go.seankhliao.com/mono/goreleases"
	"go.seankhliao.com/mono/run"
)

type Config struct {
	Go          bool
	Bootstrap   string
	Releases    int
	Prereleases bool
	Tip         bool

	Tools bool
}

func (c *Config) Flags(fset *flag.FlagSet, args **[]string) error {
	fset.BoolVar(&c.Go, "go", true, "update go installs")
	fset.StringVar(&c.Bootstrap, "bootstrap", "/usr/bin/go", "path to a bootstrap go install")
	fset.IntVar(&c.Releases, "releases", 2, "number of go releases to keep")
	fset.BoolVar(&c.Prereleases, "prereleases", true, "whether to get prereleases")
	fset.BoolVar(&c.Tip, "tip", false, "whether to update tip")
	fset.BoolVar(&c.Tools, "tools", true, "update go tools")

	return run.UserConfigFile(fset, "gosdkupdate.txt", false)
}

func main() {
	run.OSExec(run.Simple("gosdkupdate", "update go installations and go tools", &Config{}))
}

func (c *Config) Run(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	tmpDir, err := os.MkdirTemp("", "gosdkupdate.*")
	if err != nil {
		return fmt.Errorf("prepare temp dir: %w", err)
	}
	err = os.Chdir(tmpDir)
	if err != nil {
		return fmt.Errorf("chdir temp dir: %w", err)
	}

	err = updateGo(ctx, c, stdout)
	if err != nil {
		return fmt.Errorf("update go: %w", err)
	}

	err = updateTools(ctx, c, stdout)
	if err != nil {
		return fmt.Errorf("update tools: %w", err)
	}
	return nil
}

func updateGo(ctx context.Context, c *Config, stdout io.Writer) error {
	if !c.Go {
		return nil
	}

	toUpdate := c.Releases
	if c.Tip {
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

	if c.Releases > 0 || c.Prereleases {
		// find the current releases
		rels, err := goreleases.Releases(http.DefaultClient, ctx, "", true)
		if err != nil {
			return fmt.Errorf("get go releases: %w", err)
		}

		need := c.Releases
		var toKeep []string
		var lastLang string
		for i, rel := range rels {
			if !rel.Stable {
				if i == 0 && c.Prereleases {
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
		if c.Tip {
			toUpdate++
		}
		spin.FinalMSG = fmt.Sprintf("%2d/%2d Go installations updated\n", toUpdate, toUpdate)

		for i, rel := range toKeep {
			spin.Suffix = fmt.Sprintf("%2d/%2d installing %s", i+1, toUpdate, rel)

			cmd := exec.CommandContext(ctx, c.Bootstrap, "env", "GOROOT")
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

	if c.Tip {
		spin.Suffix = fmt.Sprintf("%2d/%2d installing tip", toUpdate, toUpdate)

		home, err := os.UserHomeDir()
		if err != nil {
			return fmt.Errorf("get home dir: %w", err)
		}

		gotipDir := filepath.Join(home, "sdk/go")

		var isJJ, isGit bool
		vcsJJ, vcsGit := filepath.Join(gotipDir, ".jj"), filepath.Join(".git")
		_, err = os.Stat(vcsJJ)
		if err == nil {
			isJJ = true
		}
		_, err = os.Stat(vcsGit)
		if err == nil {
			isGit = true
		}

		if isJJ {
			cmd := exec.CommandContext(ctx, "jj", "git", "fetch")
			cmd.Dir = gotipDir
			_, err := cmd.CombinedOutput()
			if err != nil {
				return fmt.Errorf("update go repo: %w", err)
			}
			cmd = exec.CommandContext(ctx, "jj", "new", "master")
			cmd.Dir = gotipDir
			_, err = cmd.CombinedOutput()
			if err != nil {
				return fmt.Errorf("move workspace ref: %w", err)
			}

		} else if isGit {
			cmd := exec.CommandContext(ctx, "git", "checkout", "master")
			cmd.Dir = gotipDir
			_, err := cmd.CombinedOutput()
			if err != nil {
				return fmt.Errorf("checkout master: %w", err)
			}
			cmd = exec.CommandContext(ctx, "git", "pull", "--ff-only")
			cmd.Dir = gotipDir
			_, err = cmd.CombinedOutput()
			if err != nil {
				return fmt.Errorf("git pull: %w", err)
			}

		} else {
			cmd := exec.CommandContext(ctx, "jj", "git", "clone", "https://go.googlesource.com/go", gotipDir)
			_, err := cmd.CombinedOutput()
			if err != nil {
				return fmt.Errorf("clone go repo: %w", err)
			}
		}

		srcDir := filepath.Join(gotipDir, "src")
		cmd := exec.CommandContext(ctx, "bash", "./make.bash")
		cmd.Env = append(cmd.Env, "GOENV=off")
		cmd.Dir = srcDir
		_, err = cmd.CombinedOutput()
		if err != nil {
			return fmt.Errorf("build go: %w", err)
		}

		gotipGo := filepath.Join(gotipDir, "bin/go")
		gopath := os.Getenv("GOPATH")
		if gopath == "" {
			return fmt.Errorf("GOPATH not set in env")
		}
		gobinGo := filepath.Join(gopath, "bin/go")
		err = os.Symlink(gotipGo, gobinGo)
		if err != nil {
			return fmt.Errorf("symlink %s => %s: %w", gobinGo, gotipGo, err)
		}
	}

	return nil
}

func updateTools(ctx context.Context, c *Config, stdout io.Writer) error {
	if !c.Tools {
		return nil
	}

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
