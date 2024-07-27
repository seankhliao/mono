package main

import (
	"bytes"
	"errors"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"time"

	"go.seankhliao.com/mono/ycli"
)

const versionFile = "testrepo-version"

func cmdNew() ycli.Command {
	var name string
	return ycli.New(
		"new",
		"creates a new repository",
		func(fs *flag.FlagSet) {
			fs.StringVar(&name, "name", "", "create a named repository in the current directory")
		},
		func(stdout, stderr io.Writer) error {
			var base string
			if name == "" {
				var err error
				name, err = newTestrepoVersion()
				if err != nil {
					return fmt.Errorf("repos new: get repo sequence: %w", err)
				}

				base, err = os.UserHomeDir()
				if err != nil {
					return fmt.Errorf("repos new: get home dir: %w", err)
				}
				base = filepath.Join(base, "tmp")
			} else {
				var err error
				base, err = os.Getwd()
				if err != nil {
					return fmt.Errorf("repos new: get current dir: %w", err)
				}
			}

			err := runNew(stdout, base, name)
			if err != nil {
				return fmt.Errorf("repos new: %w", err)
			}
			return nil
		},
	)
}

func runNew(stdout io.Writer, base, name string) error {
	fp := filepath.Join(base, name)
	err := os.MkdirAll(fp, 0o755)
	if err != nil {
		return fmt.Errorf("mkdir %s: %w", fp, err)
	}

	cmd := exec.Command("go", "mod", "init", "go.seankhliao.com/"+name)
	cmd.Dir = fp
	out, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("go mod init: %w\n%s", err, out)
	}

	cmd = exec.Command("git", "init")
	cmd.Dir = fp
	out, err = cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("git init: %w\n%s", err, out)
	}

	cmd = exec.Command("git", "commit", "--allow-empty", "-m", "root-commit")
	cmd.Dir = fp
	out, err = cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("git commit: %w\n%s", err, out)
	}

	cmd = exec.Command("git", "remote", "add", "origin", "s:"+name)
	cmd.Dir = fp
	out, err = cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("git remote add: %w\n%s", err, out)
	}

	lf := filepath.Join(fp, "LICENSE")
	f, err := os.Create(lf)
	if err != nil {
		return fmt.Errorf("create %s: %w", lf, err)
	}
	defer f.Close()
	err = licenseTpl.Execute(f, map[string]string{
		"Date": time.Now().Format("2006"),
	})
	if err != nil {
		return fmt.Errorf("render license: %w", err)
	}

	lf = filepath.Join(fp, "README.md")
	f, err = os.Create(lf)
	if err != nil {
		return fmt.Errorf("create %s: %w", lf, err)
	}
	defer f.Close()
	err = readmeTpl.Execute(f, map[string]string{
		"Name": name,
	})
	if err != nil {
		return fmt.Errorf("render readme: %w", err)
	}

	fmt.Fprintln(stdout, "cd", fp)
	return nil
}

func newTestrepoVersion() (string, error) {
	cacheDir, err := os.UserCacheDir()
	if err != nil {
		return "", fmt.Errorf("get cache dir: %w", err)
	}
	vf := filepath.Join(cacheDir, versionFile)
	b, err := os.ReadFile(vf)
	if err != nil && !errors.Is(err, fs.ErrNotExist) {
		return "", fmt.Errorf("read %s: %w", vf, err)
	}
	b, _, _ = bytes.Cut(b, []byte("\n"))
	ctr, _ := strconv.Atoi(string(b))
	ctr++

	err = os.WriteFile(vf, []byte(strconv.Itoa(ctr)), 0o644)
	if err != nil {
		return "", fmt.Errorf("write %s: %w", vf, err)
	}

	name := fmt.Sprintf("testrepo%04d", ctr)
	return name, nil
}
