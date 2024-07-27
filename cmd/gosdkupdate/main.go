// Command gosdkupdate keeps the latest patch version of each minor go version available
// via the golang.org/dl wrappers.
// It also updates gotip to the current tip.
package main

import (
	"bytes"
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"os/exec"
	"os/signal"
	"path"
	"path/filepath"
	"strings"
	"sync"
	"syscall"

	"go.seankhliao.com/mono/cmd/gosdkupdate/goreleases"
)

func main() {
	var minMinor, parallel int
	var bootStrapGo string
	flag.IntVar(&minMinor, "min-minor", 11, "earliest minor version to keep")
	flag.StringVar(&bootStrapGo, "bootstrap-go", "/usr/bin/go", "path to `go` for installing versions")
	flag.IntVar(&parallel, "parallel", 3, "parallel downloads")
	flag.Parse()

	ctx := context.Background()
	ctx, stop := signal.NotifyContext(ctx, syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	client := goreleases.New(nil, "")
	rels, err := client.Releases(ctx, true)
	if err != nil {
		log.Fatalln("get go releases", err)
	}

	versionMap := make(map[int]goreleases.Version)
	for _, rel := range rels {
		_, minor, _, _, _ := rel.Version.Parts()
		orel, ok := versionMap[minor]
		if !ok {
			versionMap[minor] = rel.Version
			continue
		}
		larger := compVersion(rel.Version, orel)
		if larger == "" {
			panic("no larger version: " + string(rel.Version) + " " + string(orel))
		}
		versionMap[minor] = larger
	}

	toKeep := map[string]struct{}{
		"gotip": {},
	}
	for minor, rel := range versionMap {
		if minor < minMinor {
			continue
		}
		toKeep[string(rel)] = struct{}{}
	}
	fmt.Println("keeping sdks:", toKeep)

	home, err := os.UserHomeDir()
	if err != nil {
		log.Fatalln("unknown user home dir", err)
	}
	homeSdk := filepath.Join(home, "sdk")
	installedSdks, err := os.ReadDir(homeSdk)
	if err != nil {
		log.Fatalln("read", homeSdk, err)
	}
	for _, sdk := range installedSdks {
		// ignore non go* directories, eg x/ repos
		if !strings.HasPrefix(sdk.Name(), "go") {
			continue
		}
		_, ok := toKeep[sdk.Name()]
		if !ok {
			sdkPath := path.Join(homeSdk, sdk.Name())
			err = os.RemoveAll(sdkPath)
			if err != nil {
				log.Fatalln("removing", sdkPath, err)
			}
		}
	}

	var gobin string
	gobinraw, err := exec.CommandContext(ctx, bootStrapGo, "env", "GOBIN").CombinedOutput()
	if err != nil || len(bytes.TrimSpace(gobinraw)) == 0 {
		gopathraw, err := exec.CommandContext(ctx, bootStrapGo, "env", "GOPATH").CombinedOutput()
		if err != nil {
			log.Fatalln("go env GOPATH", err, string(gopathraw))
		}
		gobin = filepath.Join(string(bytes.TrimSpace(gopathraw)), "bin")
	} else {
		gobin = string(bytes.TrimSpace(gobinraw))
	}

	fmt.Println("resolved GOBIN:", gobin)
	binFiles, err := os.ReadDir(gobin)
	if err != nil {
		log.Fatalln("read GOBIN", gobin)
	}
	for _, file := range binFiles {
		if file.Name() == "go" {
			err = os.Remove(filepath.Join(gobin, file.Name()))
			if err != nil {
				log.Fatalln("removing local go", err)
			}
		}
		if !strings.HasPrefix(file.Name(), "go1.") {
			continue
		}
		if _, ok := toKeep[file.Name()]; !ok {
			binPath := filepath.Join(gobin, file.Name())
			err = os.RemoveAll(binPath)
			if err != nil {
				log.Fatalln("remove file", binPath, err)
			}
		}
	}

	var envs []string
	for _, s := range os.Environ() {
		if strings.HasPrefix(s, "PATH=") {
			envs = append(envs, "PATH="+filepath.Dir(bootStrapGo))
			continue
		}
		envs = append(envs, s)
	}

	sem := make(chan struct{}, parallel)

	var wg sync.WaitGroup
	for ver := range toKeep {
		sem <- struct{}{}
		wg.Add(1)
		go func(ver string) {
			defer func() { <-sem }()
			defer wg.Done()
			args := []string{"install", fmt.Sprintf("golang.org/dl/%v@latest", ver)}
			fmt.Println(bootStrapGo, args)
			cmd := exec.CommandContext(ctx, bootStrapGo, args...)
			cmd.Env = envs
			out, err := cmd.CombinedOutput()
			if err != nil {
				log.Println("install shim", ver, err, "output\n", string(out))
				return
			}
			cmd = exec.CommandContext(ctx, ver, "download")
			out, err = cmd.CombinedOutput()
			if err != nil {
				log.Println("download sdk", ver, err, "output\n", string(out))
			}
			log.Println("downloaded", ver)
		}(ver)
	}

	wg.Wait()

	os.Symlink(filepath.Join(gobin, "gotip"), filepath.Join(gobin, "go"))
}

func compVersion(a, b goreleases.Version) goreleases.Version {
	amajor, aminor, apatch, arc, abeta := a.Parts()
	bmajor, bminor, bpatch, brc, bbeta := b.Parts()
	rel := compab(a, b, amajor, bmajor)
	if rel != nil {
		return *rel
	}
	rel = compab(a, b, aminor, bminor)
	if rel != nil {
		return *rel
	}
	rel = compab(a, b, apatch, bpatch)
	if rel != nil {
		return *rel
	}
	if arc+abeta == 0 {
		return a
	} else if brc+bbeta == 0 {
		return b
	}
	rel = compab(a, b, arc, brc)
	if rel != nil {
		return *rel
	}
	rel = compab(a, b, abeta, bbeta)
	if rel != nil {
		return *rel
	}
	return ""
}

func compab(a, b goreleases.Version, an, bn int) *goreleases.Version {
	if an > bn {
		return &a
	} else if bn > an {
		return &b
	}
	return nil
}
