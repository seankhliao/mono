package main

import (
	"bufio"
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
	"maragu.dev/gomponents"
	"maragu.dev/gomponents/html"
)

const (
	singleKey = ":single"
)

func stripTitles(src []byte) (page []byte, title, subtitle string) {
	buf := new(bytes.Buffer)
	sc := bufio.NewScanner(bytes.NewReader(src))
	for sc.Scan() {
		b := sc.Bytes()
		switch {
		case bytes.HasPrefix(b, []byte("# ")):
			title = string(b[2:])
		case bytes.HasPrefix(b, []byte("## ")):
			subtitle = string(b[3:])
		default:
			buf.Write(b)
			buf.WriteRune('\n')
		}
	}
	page = buf.Bytes()
	return
}

func renderSingle(in string, compact bool) (map[string]*bytes.Buffer, error) {
	b, err := os.ReadFile(in)
	if err != nil {
		return nil, fmt.Errorf("read file: %w", err)
	}
	b, title, subtitle := stripTitles(b)
	rawHTML, rawCSS, err := webstyle.Markdown(b)
	if err != nil {
		return nil, fmt.Errorf("parse markdown: %w", err)
	}
	buf := new(bytes.Buffer)
	o := webstyle.NewOptions(
		title,
		subtitle,
		[]gomponents.Node{gomponents.Raw(string(rawHTML))})
	o.CustomCSS = string(rawCSS)
	o.CompactStyle = compact
	err = webstyle.Structured(buf, o)
	if err != nil {
		return nil, fmt.Errorf("render result: %w", err)
	}
	return map[string]*bytes.Buffer{singleKey: buf}, nil
}

func renderMulti(in, gtm, baseUrl string, compact bool) (map[string]*bytes.Buffer, error) {
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

		buf := new(bytes.Buffer)
		if strings.HasSuffix(p, ".md") {
			u := baseUrl + canonicalPathFromRelPath(p)

			b, err := io.ReadAll(inFile)
			if err != nil {
				return fmt.Errorf("read file: %w", err)
			}
			b, title, subtitle := stripTitles(b)
			rawHTML, rawCSS, err := webstyle.Markdown(b)
			if err != nil {
				return fmt.Errorf("render markdown: %w", err)
			}

			o := webstyle.NewOptions(
				title,
				subtitle,
				[]gomponents.Node{gomponents.Raw(string(rawHTML))},
			)
			o.CompactStyle = compact
			o.CanonicalURL = u
			o.CustomCSS = string(rawCSS)

			if strings.HasSuffix(p, "/index.md") { // exclude root index
				list, err := directoryList(fsys, p)
				if err != nil {
					return err
				}
				o.Content = append(o.Content, list)
			}

			err = webstyle.Structured(buf, o)
			if err != nil {
				return fmt.Errorf("render: %w", err)
			}

			fmt.Fprintf(&siteMapTxt, "%s\n", u)
			p = p[:len(p)-3] + ".html"
		} else if strings.HasSuffix(p, ".cue") {
			u := baseUrl + canonicalPathFromRelPath(p)
			err = processTable(buf, inFile, u, gtm)
			if err != nil {
				return fmt.Errorf("process table: %w", err)
			}
			fmt.Fprintf(&siteMapTxt, "%s\n", u)
			p = p[:len(p)-4] + ".html"
		} else {
			_, err = io.Copy(buf, inFile)
			if err != nil {
				return fmt.Errorf("copy: %w", err)
			}
		}

		rendered[p] = buf

		return nil
	})
	if err != nil {
		return nil, fmt.Errorf("process source: %w", err)
	}

	rendered["sitemap.txt"] = &siteMapTxt

	spin.FinalMSG = fmt.Sprintf("%3d rendered pages\n", len(rendered))

	return rendered, nil
}

func directoryList(fsys fs.FS, p string) (gomponents.Node, error) {
	des, err := fs.ReadDir(fsys, filepath.Dir(p))
	if err != nil {
		return nil, fmt.Errorf("read dir: %w", err)
	}

	// reverse order
	slices.SortFunc(des, func(a, b fs.DirEntry) int {
		return strings.Compare(b.Name(), a.Name())
	})

	entries := make([]gomponents.Node, 0, len(des))
	for _, de := range des {
		if de.IsDir() || de.Name() == "index.md" {
			continue
		}
		n := de.Name() // 120XX-YY-ZZ-some-title.md
		if strings.HasPrefix(n, "120") && len(n) > 15 && n[11] == '-' {
			entries = append(entries, html.Li(
				html.Time(
					html.DateTime(n[1:11]),  // 20XX-YY-ZZ
					gomponents.Text(n[:11]), // 120XX-YY-ZZ
				),
				gomponents.Text(" | "),
				html.A(
					html.Href(n[:len(n)-3]+"/"),                                   // 120XX-YY-ZZ-some-title/
					gomponents.Text(strings.ReplaceAll(n[12:len(n)-3], "-", " ")), // some title
				),
			))
		}
	}
	return html.Ul(entries...), nil
}

func canonicalPathFromRelPath(in string) string {
	in = strings.TrimSuffix(in, ".md")
	in = strings.TrimSuffix(in, ".html")
	in = strings.TrimSuffix(in, ".cue")
	in = strings.TrimSuffix(in, "index")
	if in == "" {
		return "/"
	} else if in[len(in)-1] == '/' {
		return "/" + in
	}
	return "/" + in + "/"
}
