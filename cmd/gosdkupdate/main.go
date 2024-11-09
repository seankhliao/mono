// Command gosdkupdate keeps the latest patch version of each minor go version available
// via the golang.org/dl wrappers.
// It also updates gotip to the current tip.
package main

import (
	"context"
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

	"go.seankhliao.com/mono/cmd/gosdkupdate/goreleases"
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
}

func (a *App) register(fset *flag.FlagSet) {
	fset.IntVar(&a.keepMinor, "keep-minor", 3, "number of released minor versions to keep")
	fset.IntVar(&a.parallel, "parallel", 4, "parallel downloads")
	fset.StringVar(&a.bootstrap, "bootstrap", "/usr/bin/go", "path to bootstrap go")
}

func (a *App) run(stdout, stderr io.Writer) error {
	ctx := context.Background()

	rels, err := goreleases.Releases(http.DefaultClient, ctx, "", true)
	if err != nil {
		return fmt.Errorf("get go releases: %w", err)
	}

	// sort newest first
	var keepLang []string
	slices.SortFunc(rels, func(a, b goreleases.Release) int {
		return version.Compare(b.Version, a.Version)
	})
	for _, rel := range rels {
		keepLang = append(keepLang, version.Lang(rel.Version))
	}
	keepLang = slices.Compact(keepLang)
	keepLang = keepLang[:a.keepMinor]

	// things to keep
	var keepVer []string
	for _, lang := range keepLang {
		for _, rel := range rels {
			if version.Lang(rel.Version) == lang {
				keepVer = append(keepVer, rel.Version)
				break
			}
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
		if !slices.Contains(keepLang, version.Lang(de.Name())) {
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
		if !slices.Contains(keepLang, version.Lang(de.Name())) {
			os.RemoveAll(filepath.Join(gobin, de.Name()))
		}
	}

	// dwnload
	sem := make(chan struct{}, a.parallel)
	for _, sdk := range append(keepVer, "gotip") {
		sem <- struct{}{}
		go func() {
			defer func() { <-sem }()

			fmt.Fprintln(stdout, "getting", sdk)
			cmd := exec.CommandContext(ctx, a.bootstrap, "install", fmt.Sprintf("golang.org/dl/%s@latest", sdk))
			_, err := cmd.CombinedOutput()
			if err != nil {
				fmt.Fprintln(stderr, "download shim", sdk, err)
				return
			}

			cmd = exec.CommandContext(ctx, sdk, "download")
			_, err = cmd.CombinedOutput()
			if err != nil {
				fmt.Fprintln(stderr, "download sdk", sdk, err)
				return
			}

			if sdk == "gotip" {
				os.Symlink(filepath.Join(gobin, "gotip"), filepath.Join(gobin, "go"))
			}

			fmt.Fprintln(stdout, "downloaded", sdk)
		}()
	}

	// wait
	for range a.parallel {
		sem <- struct{}{}
	}
	return nil
}
