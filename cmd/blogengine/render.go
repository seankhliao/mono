package main

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"io/fs"
	"log/slog"
	"os"
	"path/filepath"
	"slices"
	"strings"

	"go.seankhliao.com/mono/webstyle"
)

const (
	singleKey = ":single"
)

func renderSingle(ctx context.Context, lg *slog.Logger, render webstyle.Renderer, in string) (map[string]*bytes.Buffer, error) {
	lg.LogAttrs(ctx, slog.LevelDebug, "rendering single file", slog.String("file", in))
	inFile, err := os.Open(in)
	if err != nil {
		lg.LogAttrs(ctx, slog.LevelError, "open file", slog.String("file", in), slog.String("error", err.Error()))
		return nil, err
	}
	defer inFile.Close()
	var buf bytes.Buffer
	err = render.Render(&buf, inFile, webstyle.Data{})
	if err != nil {
		lg.LogAttrs(ctx, slog.LevelError, "render", slog.String("error", err.Error()))
		return nil, err
	}
	return map[string]*bytes.Buffer{singleKey: &buf}, nil
}

func renderMulti(ctx context.Context, lg *slog.Logger, render webstyle.Renderer, in, gtm, baseUrl string) (map[string]*bytes.Buffer, error) {
	lg.LogAttrs(ctx, slog.LevelDebug, "rendering directory", slog.String("dir", in))

	var siteMapTxt bytes.Buffer
	rendered := make(map[string]*bytes.Buffer)
	fsys := os.DirFS(in)
	err := fs.WalkDir(fsys, ".", func(p string, d fs.DirEntry, err error) error {
		if err != nil || d.IsDir() {
			return err
		}
		lg := lg.With(slog.String("src", p))

		inFile, err := fsys.Open(p)
		if err != nil {
			lg.LogAttrs(ctx, slog.LevelError, "open file", slog.String("error", err.Error()))
			return err
		}
		defer inFile.Close()

		var buf bytes.Buffer
		if strings.HasSuffix(p, ".md") {
			data := webstyle.Data{
				GTM: gtm,
			}

			if p == "index.md" { // root index
				data.Desc = `hi, i'm sean, available for adoption by extroverts for the low, low cost of your love.`
			} else if strings.HasSuffix(p, "/index.md") { // exclude root index
				data.Main, err = directoryList(ctx, lg, fsys, p)
				if err != nil {
					return err
				}
			}

			lg.LogAttrs(ctx, slog.LevelDebug, "rendering page")
			err = render.Render(&buf, inFile, data)
			if err != nil {
				lg.LogAttrs(ctx, slog.LevelError, "render", slog.String("error", err.Error()))
				return err
			}

			fmt.Fprintf(&siteMapTxt, "%s%s\n", baseUrl, canonicalPathFromRelPath(p))
			p = p[:len(p)-3] + ".html"
		} else {
			lg.LogAttrs(ctx, slog.LevelDebug, "copying static file")
			_, err = io.Copy(&buf, inFile)
			if err != nil {
				lg.LogAttrs(ctx, slog.LevelError, "copy file", slog.String("error", err.Error()))
				return err
			}
		}

		rendered[p] = &buf

		return nil
	})
	if err != nil {
		lg.LogAttrs(ctx, slog.LevelError, "walk", slog.String("file", in), slog.String("error", err.Error()))
		return nil, err
	}

	rendered["sitemap.txt"] = &siteMapTxt
	return rendered, nil
}

func directoryList(ctx context.Context, lg *slog.Logger, fsys fs.FS, p string) (string, error) {
	lg.LogAttrs(ctx, slog.LevelDebug, "creating index listing")
	des, err := fs.ReadDir(fsys, filepath.Dir(p))
	if err != nil {
		lg.LogAttrs(ctx, slog.LevelError, "readdir", slog.String("dir", filepath.Dir(p)), slog.String("error", err.Error()))
		return "", err
	}

	// reverse order
	slices.SortFunc(des, func(a, b fs.DirEntry) int {
		if a.Name() > b.Name() {
			return -1
		} else if a.Name() == b.Name() {
			return 0
		}
		return 1
	})

	var buf bytes.Buffer
	buf.WriteString("<ul>\n")
	for _, de := range des {
		if de.IsDir() || de.Name() == "index.md" {
			continue
		}
		n := de.Name() // 120XX-YY-ZZ-some-title.md
		if strings.HasPrefix(n, "120") && len(n) > 15 && n[11] == '-' {
			fmt.Fprintf(&buf, `<li><time datetime="%s">%s</time> | <a href="%s">%s</a></li>`,
				n[1:11],          // 20XX-YY-ZZ
				n[:11],           // 120XX-YY-ZZ
				n[:len(n)-3]+"/", // 120XX-YY-ZZ-some-title/
				strings.ReplaceAll(n[12:len(n)-3], "-", " "), // some title
			)
		}
	}
	buf.WriteString("</ul>\n")
	return buf.String(), nil
}

func canonicalPathFromRelPath(in string) string {
	in = strings.TrimSuffix(in, ".md")
	in = strings.TrimSuffix(in, ".html")
	in = strings.TrimSuffix(in, "index")
	if in == "" {
		return "/"
	} else if in[len(in)-1] == '/' {
		return "/" + in
	}
	return "/" + in + "/"
}
