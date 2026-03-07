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

	"go.seankhliao.com/mono/cmdline"
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
	cmdline.RunOS(&cmdline.CommandBasic[Config]{
		Name: "blogengine",
		Desc: "markdown to html renderer, with firebase hosting integration",
		Flags: func(c *Config, fset *flag.FlagSet) error {
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

			return cmdline.ChdirToParentFlagFile(fset, "blogengine.txt")
		},
		Do: func(c *Config) cmdline.Runner {
			return func(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) int {
				ctx, done := signal.NotifyContext(ctx, syscall.SIGINT, syscall.SIGTERM)
				defer done()

				fi, err := os.Stat(c.Source)
				if err != nil {
					fmt.Fprintln(stderr, "stat source:", err)
					return 1
				} else if !fi.IsDir() {
					fmt.Fprintln(stderr, "src must be a directory")
					return 1
				}

				rendered, err := renderMulti(ctx, c.Source, c.GoogleTagManager, c.BaseURL, c.Compact)
				if err != nil {
					fmt.Fprintln(stderr, "render:", err)
					return 1
				}

				if c.Preview {
					err = servePreview(ctx, stdout, rendered)
					if err != nil {
						fmt.Fprintln(stderr, "serve preview", err)
						return 1
					}
					return 0
				}

				if c.Destination != "" {
					err = writeRendered(ctx, stdout, rendered, c.Destination)
					if err != nil {
						fmt.Fprintln(stderr, "write to dst", c.Destination, err)
						return 1
					}
				}

				if c.Firebase.SiteID != "" {
					err = uploadFirebase(ctx, stdout, rendered, c.Firebase)
					if err != nil {
						fmt.Fprintln(stderr, "firebase upload:", err)
						return 1
					}
				}

				return 0
			}
		},
	})
}
