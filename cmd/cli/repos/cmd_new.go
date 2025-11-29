package main

import (
	"bytes"
	_ "embed"
	"errors"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"strconv"
	"time"

	"go.seankhliao.com/mono/ycli"
)

const (
	versionFile = "testrepo-version"

	licenseFmt = `MIT License

Copyright (c) %[1]s Sean Liao

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
`

	readmeFmt = `# %[1]s

[![Go Reference][pkgsitebadge]][pkgsite]
[![License][licensebadge]](LICENSE)

[licensebadge]: https://img.shields.io/github/license/seankhliao/%[2]s.svg?style=flat-square
[pkgsitebadge]: https://pkg.go.dev/badge/%[1]s/%[2]s.svg
[pkgsite]: https://pkg.go.dev/%[1]s/%[2]s
`
)

func cmdNew(conf *CommonConfig) ycli.Command {
	var modPrefix string
	var srcPrefix string
	var name string
	var jj bool
	return ycli.New(
		"new",
		"creates a new repository",
		func(fs *flag.FlagSet) {
			fs.StringVar(&modPrefix, "module-prefix", "go.seankhliao.com", "go module prefix")
			fs.StringVar(&srcPrefix, "src-prefix", "https://github.com/seankhliao", "vcs source prefix")
			fs.StringVar(&name, "name", "", "create a named repository in the current directory")
			fs.BoolVar(&jj, "jj", true, "use jj as the vcs tool")
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

			err := runNew(conf.eval, base, srcPrefix, modPrefix, name, jj)
			if err != nil {
				return fmt.Errorf("repos new: %w", err)
			}
			return nil
		},
	)
}

func runNew(evalFile io.Writer, base, srcPrefix, modPrefix, name string, jj bool) error {
	fp := filepath.Join(base, name)
	err := os.MkdirAll(fp, 0o755)
	if err != nil {
		return fmt.Errorf("mkdir %s: %w", fp, err)
	}

	modName := path.Join(modPrefix, name)
	srcName := path.Join(srcPrefix, name)

	cmd := exec.Command("go", "mod", "init", modName)
	cmd.Dir = fp
	out, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("go mod init: %w\n%s", err, out)
	}

	if jj {
		cmd = exec.Command("jj", "git", "init", "--colocate")
		cmd.Dir = fp
		out, err = cmd.CombinedOutput()
		if err != nil {
			return fmt.Errorf("jj git init: %w\n%s", err, out)
		}

		cmd = exec.Command("jj", "git", "remote", "add", "origin", srcName)
		cmd.Dir = fp
		out, err = cmd.CombinedOutput()
		if err != nil {
			return fmt.Errorf("git remote add: %w\n%s", err, out)
		}
	} else {
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

		cmd = exec.Command("git", "remote", "add", "origin", srcName)
		cmd.Dir = fp
		out, err = cmd.CombinedOutput()
		if err != nil {
			return fmt.Errorf("git remote add: %w\n%s", err, out)
		}
	}

	lf := filepath.Join(fp, "LICENSE")
	f, err := os.Create(lf)
	if err != nil {
		return fmt.Errorf("create %s: %w", lf, err)
	}
	defer f.Close()
	_, err = fmt.Fprintf(f, licenseFmt, time.Now().Format("2006"))
	if err != nil {
		return fmt.Errorf("render license: %w", err)
	}

	lf = filepath.Join(fp, "README.md")
	f, err = os.Create(lf)
	if err != nil {
		return fmt.Errorf("create %s: %w", lf, err)
	}
	defer f.Close()
	_, err = fmt.Fprintf(f, readmeFmt, modPrefix, name)
	if err != nil {
		return fmt.Errorf("render readme: %w", err)
	}

	fmt.Fprintln(evalFile, "cd", fp)
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
