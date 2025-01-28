package main

import (
	"bytes"
	"io/fs"
	"os"
	"path"
	"regexp"
	"runtime/debug"
	"strings"
	"testing"

	"mvdan.cc/gofumpt/format"
)

var generatedRe = regexp.MustCompile(`(?m)^// Code generated .* DO NOT EDIT\.$`)

func TestGofumpt(t *testing.T) {
	buildinfo, ok := debug.ReadBuildInfo()
	if !ok {
		t.Fatal("failed to get embedded build info")
	}
	version := buildinfo.GoVersion
	if strings.HasPrefix(version, "devel") {
		_, version, _ = strings.Cut(version, " ")
		version, _, _ = strings.Cut(version, "-")
	}

	opts := format.Options{
		LangVersion: version,
		ModulePath:  buildinfo.Main.Path,
		ExtraRules:  true,
	}

	fsys := os.DirFS(".")
	err := fs.WalkDir(fsys, ".", func(p string, d fs.DirEntry, err error) error {
		if d.IsDir() && (d.Name() == "vendor" || d.Name() == "testdata") {
			return fs.SkipDir
		}
		if err != nil || d.IsDir() || path.Ext(p) != ".go" {
			return err
		}
		t.Run(p, func(t *testing.T) {
			in, err := fs.ReadFile(fsys, p)
			if err != nil {
				t.Fatal("failed to read file:", err)
			}

			i := bytes.Index(in, []byte("\npackage "))
			if i > 0 {
				if generatedRe.Match(in) {
					t.Skip("generated file")
					return
				}
			}

			out, err := format.Source(in, opts)
			if err != nil {
				t.Fatal("failed to format:", err)
			}
			if !bytes.Equal(in, out) {
				t.Fatal("file not formatted")
			}
		})
		return nil
	})
	if err != nil {
		t.Error("unexpected error:", err)
	}
}
