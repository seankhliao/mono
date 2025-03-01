// Command gosdkupdate keeps the latest patch version of each minor go version available
// via the golang.org/dl wrappers.
// It also updates gotip to the current tip.
package main

import (
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
	"slices"
	"strings"

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

	updateTools bool
}

func (a *App) register(fset *flag.FlagSet) {
	fset.IntVar(&a.keepMinor, "keep-minor", 3, "number of released minor versions to keep")
	fset.IntVar(&a.parallel, "parallel", 4, "parallel downloads")
	fset.StringVar(&a.bootstrap, "bootstrap", "/usr/bin/go", "path to bootstrap go")
	fset.BoolVar(&a.updateTools, "update-tools", true, "update tools in GOBIN")
}

func (a *App) run(stdout, stderr io.Writer) error {
	ctx := context.Background()

	// get current releases
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

	// clean up ~/sdk
	home, err := os.UserHomeDir()
	if err != nil {
		return fmt.Errorf("get user home: %w", err)
	}
	sdkPath := filepath.Join(home, "sdk")
	des, err := os.ReadDir(sdkPath)
	if err != nil {
		return fmt.Errorf("get installed sdks: %w", err)
	}
	for _, de := range des {
		if !strings.HasPrefix(de.Name(), "go1") {
			// sub repos
			continue
		}
		if !slices.Contains(keepVer, de.Name()) {
			os.RemoveAll(filepath.Join(sdkPath, de.Name()))
		}
	}

	// clean up gobin
	gobin := os.Getenv("GOBIN")
	if gobin == "" {
		gobin = filepath.Join(os.Getenv("GOPATH"), "bin")
	}
	if gobin == "" {
		return fmt.Errorf("can't deduce GOBIN")
	}
	os.RemoveAll(filepath.Join(gobin, "go"))
	os.RemoveAll(filepath.Join(gobin, "gotip"))

	des, err = os.ReadDir(gobin)
	if err != nil {
		return fmt.Errorf("get installed sdk shims: %w", err)
	}
	for _, de := range des {
		if !strings.HasPrefix(de.Name(), "go1") {
			// sub repos
			continue
		}
		if !slices.Contains(keepVer, de.Name()) {
			os.RemoveAll(filepath.Join(gobin, de.Name()))
		}
	}

	// download versions
	sem := make(chan struct{}, a.parallel)
	for _, sdk := range append(keepVer, "gotip") {
		sem <- struct{}{}
		go func() {
			defer func() { <-sem }()
			errInstall := a.installSDK(ctx, gobin, sdk)
			if errInstall != nil {
				fmt.Fprintln(stderr, "error installing", sdk, errInstall)
				return
			}
			fmt.Fprintln(stdout, "downloaded", sdk)
		}()
	}

	// wait
	for range a.parallel {
		sem <- struct{}{}
	}
	// clear for reuse
	for range a.parallel {
		<-sem
	}

	if !a.updateTools {
		return nil
	}

	des, err = os.ReadDir(gobin)
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

	if sdk == "gotip" {
		os.Symlink(filepath.Join(gobin, "gotip"), filepath.Join(gobin, "go"))
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
