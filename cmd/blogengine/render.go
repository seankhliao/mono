package main

import (
	"bytes"
	"fmt"
	"io"
	"io/fs"
	"os"
	"path/filepath"
	"slices"
	"strings"
	"time"

	"github.com/briandowns/spinner"
	"go.seankhliao.com/mono/webstyle"
)

const (
	singleKey = ":single"
)

func renderSingle(stdout io.Writer, render webstyle.Renderer, in string) (map[string]*bytes.Buffer, error) {
	inFile, err := os.Open(in)
	if err != nil {
		return nil, fmt.Errorf("open file: %w", err)
	}
	defer inFile.Close()
	var buf bytes.Buffer
	err = render.Render(&buf, inFile, webstyle.Data{})
	if err != nil {
		return nil, fmt.Errorf("render: %w", err)
	}
	return map[string]*bytes.Buffer{singleKey: &buf}, nil
}

func renderMulti(stdout io.Writer, render webstyle.Renderer, in, gtm, baseUrl string) (map[string]*bytes.Buffer, error) {
	var countFiles int
	fsys := os.DirFS(in)
	err := fs.WalkDir(fsys, ".", func(p string, d fs.DirEntry, err error) error {
		if err != nil || d.IsDir() {
			return err
		}
		countFiles++
		return nil
	})
	if err != nil {
		return nil, fmt.Errorf("walk source: %w", err)
	}
	spin := spinner.New(spinner.CharSets[39], 100*time.Millisecond)
	spin.Start()
	defer spin.Stop()
	var idx int

	var siteMapTxt bytes.Buffer
	rendered := make(map[string]*bytes.Buffer)
	err = fs.WalkDir(fsys, ".", func(p string, d fs.DirEntry, err error) error {
		if err != nil || d.IsDir() {
			return err
		}

		idx++
		spin.Suffix = fmt.Sprintf("%3d processing %q", idx, p)

		inFile, err := fsys.Open(p)
		if err != nil {
			return fmt.Errorf("open file: %w", err)
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
				data.Main, err = directoryList(fsys, p)
				if err != nil {
					return err
				}
			}

			err = render.Render(&buf, inFile, data)
			if err != nil {
				return fmt.Errorf("render: %w", err)
			}

			fmt.Fprintf(&siteMapTxt, "%s%s\n", baseUrl, canonicalPathFromRelPath(p))
			p = p[:len(p)-3] + ".html"
		} else {
			_, err = io.Copy(&buf, inFile)
			if err != nil {
				return fmt.Errorf("copy: %w", err)
			}
		}

		rendered[p] = &buf

		return nil
	})
	if err != nil {
		return nil, fmt.Errorf("process source: %w", err)
	}

	rendered["sitemap.txt"] = &siteMapTxt

	spin.FinalMSG = fmt.Sprintf("%3d rendered pages\n", len(rendered))

	return rendered, nil
}

func directoryList(fsys fs.FS, p string) (string, error) {
	des, err := fs.ReadDir(fsys, filepath.Dir(p))
	if err != nil {
		return "", fmt.Errorf("read dir: %w", err)
	}

	// reverse order
	slices.SortFunc(des, func(a, b fs.DirEntry) int {
		return strings.Compare(b.Name(), a.Name())
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
