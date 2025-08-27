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
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"

	"go.seankhliao.com/mono/goreleases"
	"go.seankhliao.com/mono/ycli"
)

func main() {
	var a App
	ycli.OSExec(ycli.New(
		"gosdkupdate",
		"keep up to date go toolchains",
		a.register,
		a.run,
	))
}

type App struct {
	keepMinor int
	parallel  int
	bootstrap string

	updateTip   bool
	updateGo    bool
	updateTools bool
}

func (a *App) register(fset *flag.FlagSet) {
	fset.IntVar(&a.keepMinor, "keep-minor", 3, "number of released minor versions to keep")
	fset.IntVar(&a.parallel, "parallel", 4, "parallel downloads")
	fset.StringVar(&a.bootstrap, "bootstrap", "/usr/bin/go", "path to bootstrap go")
	fset.BoolVar(&a.updateTip, "tip", true, "install tip (dev) go version")
	fset.BoolVar(&a.updateGo, "go", true, "update go sdks")
	fset.BoolVar(&a.updateTools, "tools", true, "update tools in GOBIN")
}

func (a *App) run(stdout, stderr io.Writer) error {
	ctx := context.Background()

	gobin := os.Getenv("GOBIN")
	if gobin == "" {
		gobin = filepath.Join(os.Getenv("GOPATH"), "bin")
	}
	if gobin == "" {
		return fmt.Errorf("can't deduce GOBIN")
	}
	if a.updateTip || a.updateGo {
		des, err := os.ReadDir(gobin)
		if err != nil {
			return fmt.Errorf("dead dir %s: %w", gobin, err)
		}
		for _, de := range des {
			if a.downloadTip && de.Name() == "go" {
				os.RemoveAll(filepath.Join(gobin, "go"))
			}
			if a.downloadGo && strings.HasPrefix(de.Name(), "go1") {
				os.RemoveAll(filepath.Join(gobin, de.Name()))
			}
		}
	}

	var wg sync.WaitGroup
	if a.updateTip {
		wg.Go(func() {
			err := a.downloadTip(ctx)
			if err != nil {
					fmt.Fprintln(stderr, "download go", ver, err)
			}

		})
	}
	if a.updateGo {
		rels, err := goreleases.Releases(http.DefaultClient, ctx, "", true)
		if err != nil {
			return fmt.Errorf("get go releases: %w", err)
		}

		// map release versions to language versions
		keepVer := make([]string, 0, a.keepMinor)
		lastLang := ""
		for _, rel := range rels {
			if lang := version.Lang(rel.Version); lang != lastLang {
				lastLang = lang
				keepVer = append(keepVer, rel.Version)
			}
			if len(keepVer) >= a.keepMinor {
				break
			}
		}


		for _, ver := range keepVer {
			wg.Go(func() {
				err := a.downloadGo(ctx, ver)
				if err != nil {
					fmt.Fprintln(stderr, "download go", ver, err)
				}
			})
		}
	}

	wg.Wait()

	if !a.updateTools {
		return nil
	}

	des, err := os.ReadDir(gobin)
	if err != nil {
		return fmt.Errorf("list installed go tools: %w", err)
	}
	for _, de := range des {
		if de.Name() == "gotip" || strings.HasPrefix(de.Name(), "go1") {
			// shims we just installed
			continue
		}
		fp := filepath.Join(gobin, de.Name())
		bi, err := buildinfo.ReadFile(fp)
		if err != nil {
			//
		}

		tool := bi.Path

		sem <- struct{}{}
		go func() {
			defer func() { <-sem }()
			errInstall := a.installTool(ctx, tool)
			if errInstall != nil {
				fmt.Fprintln(stderr, "update tool", tool, errInstall)
				return
			}
			fmt.Fprintln(stdout, "updated", tool)
		}()
	}

	// wait
	for range a.parallel {
		sem <- struct{}{}
	}

	return nil
}

func (a *App) installSDK(ctx context.Context, gobin, sdk string) error {
	cmd := exec.CommandContext(ctx, a.bootstrap, "install", fmt.Sprintf("golang.org/dl/%s@latest", sdk))
	_, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("download shim: %w", err)
	}

	cmd = exec.CommandContext(ctx, sdk, "download")
	_, err = cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("download sdk: %w", err)
	}

	err = os.Symlink(filepath.Join(gobin, "gotip"), filepath.Join(gobin, "go"))
	if err != nil {
		return fmt.Errorf("set gotip as default go: %w", err)
	}
	return nil
}

func (a *App) installVersioned(ctx context.Context, gobin, ver string) error {
	cmd := exec.CommandContext(ctx, a.bootstrap, "version")
	cmd.Env = append(cmd.Env, fmt.Sprintf("GOTOOLCHAIN=%s", ver))
	_, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("download toolchain: %w", err)
	}
	cmd = exec.CommandContext(ctx, a.bootstrap, "env", "GOROOT")
	cmd.Env = append(cmd.Env, fmt.Sprintf("GOTOOLCHAIN=%s", ver))
	b, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("get downloaded goroot: %w", err)
	}
	b = bytes.TrimSpace(b)
	err = os.Symlink(filepath.Join(string(b), "bin/go"), filepath.Join(gobin, "go"+ver))
	if err != nil {
		return fmt.Errorf("link to downloaded: %w", err)
	}
	return nil
}

func (a *App) installTool(ctx context.Context, tool string) error {
	cmd := exec.CommandContext(ctx, "go", "install", fmt.Sprintf("%s@latest", tool))
	_, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("install: %w", err)
	}
	return nil
}
