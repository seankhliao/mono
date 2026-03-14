package main

import (
	"context"
	_ "embed"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"os"
	"os/signal"
	"strconv"
	"strings"
	"syscall"

	"go.seankhliao.com/mono/run"
)

//go:embed schema.cue
var configSchema string

type Config struct {
	Source string

	BaseURL          string
	Compact          bool
	GoogleTagManager string

	Preview bool

	Destination string

	Firebase Firebase
}

type Firebase struct {
	SiteID  string
	Preview bool
	Headers []struct {
		Glob    string
		Headers map[string]string
	}
	Redirects []struct {
		Glob       string
		Location   string
		StatusCode int
	}
}

func main() {
	run.OSExec(run.Simple("blogengine", "custom markdown to html static site generator", &Config{}))
}

func (c *Config) Flags(fset *flag.FlagSet, args **[]string) error {
	fset.StringVar(&c.Source, "src", "src", "path to source directory")
	fset.BoolVar(&c.Compact, "compact", false, "use compact style")
	fset.StringVar(&c.BaseURL, "base-url", "", "base url for canonicalization")
	fset.StringVar(&c.GoogleTagManager, "gtm", "", "google tag manager id")

	fset.StringVar(&c.Destination, "dst", "", "output to local directory")

	fset.BoolVar(&c.Preview, "preview", false, "serve the site on a local http server")

	fset.StringVar(&c.Firebase.SiteID, "firebase-site-id", "", "firebase site ID")
	fset.BoolVar(&c.Firebase.Preview, "firebase-preview", false, "upload to firebase in preview mode")
	fset.Func("firebase-headers", "header in format: glob key=value [key=value...]", func(s string) error {
		glob, headers, ok := strings.Cut(s, " ")
		if !ok {
			return fmt.Errorf("missing headers for glob: %s", s)
		}
		m := make(map[string]string)
		for h := range strings.SplitSeq(headers, " ") {
			k, v, ok := strings.Cut(h, "=")
			if !ok {
				return fmt.Errorf("header missing =: %v", h)
			}
			m[k] = v
		}
		c.Firebase.Headers = append(c.Firebase.Headers, struct {
			Glob    string
			Headers map[string]string
		}{
			Glob:    glob,
			Headers: m,
		})
		return nil
	})
	fset.Func("firebase-redirects", "redirects in format: glob location code", func(s string) error {
		glob, rest, ok := strings.Cut(s, " ")
		if !ok {
			return fmt.Errorf("missing rest for glob: %s", s)
		}
		location, codes, ok := strings.Cut(rest, " ")
		if !ok {
			return fmt.Errorf("missing code for location: %s", s)
		}
		code, err := strconv.Atoi(codes)
		if err != nil {
			return fmt.Errorf("invalid code for %s: %w", s, err)
		}
		c.Firebase.Redirects = append(c.Firebase.Redirects, struct {
			Glob       string
			Location   string
			StatusCode int
		}{
			Glob:       glob,
			Location:   location,
			StatusCode: code,
		})
		return nil
	})

	return run.ChdirToParentFlagFile(fset, "blogengine.txt")
}

func (c *Config) Run(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	ctx, done := signal.NotifyContext(ctx, syscall.SIGINT, syscall.SIGTERM)
	defer done()

	fi, err := os.Stat(c.Source)
	if err != nil {
		return fmt.Errorf("stat source: %w", err)
	} else if !fi.IsDir() {
		return fmt.Errorf("src must be a directory")
	}

	rendered, err := renderMulti(ctx, c.Source, c.GoogleTagManager, c.BaseURL, c.Compact)
	if err != nil {
		return fmt.Errorf("render: %w", err)
	}

	if c.Preview {
		err = servePreview(ctx, stdout, rendered)
		if err != nil {
			return fmt.Errorf("serve preview: %w", err)
		}
		return nil
	}

	if c.Destination != "" {
		err = writeRendered(ctx, stdout, rendered, c.Destination)
		if err != nil {
			return fmt.Errorf("write to dst %s: %w", c.Destination, err)
		}
	}

	if c.Firebase.SiteID != "" {
		err = uploadFirebase(ctx, stdout, rendered, c.Firebase)
		if err != nil {
			return fmt.Errorf("firebase upload: %w", err)
		}
	}

	return nil
}
