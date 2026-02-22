package main

import (
	"bytes"
	"context"
	_ "embed"
	"errors"
	"flag"
	"fmt"
	"io"
	"log/slog"
	"net"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"go.seankhliao.com/mono/cueconf"
	"go.seankhliao.com/mono/jsonlog"
	"go.seankhliao.com/mono/ycli"
	"go.seankhliao.com/mono/yhttp"
)

//go:embed schema.cue
var configSchema string

func main() {
	var configFile string
	var preview, uploadPreview bool
	ycli.OSExec(ycli.New(
		"blogengine",
		"markdown to html renderer, with firebase integration",
		func(fs *flag.FlagSet) {
			fs.StringVar(&configFile, "config", "blogengine.cue", "path to config file")
			fs.BoolVar(&preview, "preview", false, "render in memory and serve a preview")
			fs.BoolVar(&uploadPreview, "upload-preview", false, "upload to firebase in preview mode")
		},
		func(stdout, _ io.Writer) error {
			err := chdirWebRoot(configFile)
			if err != nil {
				return fmt.Errorf("blogengine: %w", err)
			}

			config, err := cueconf.ForFile[Config](configSchema, "#BlogengineConfig", configFile, false)
			if err != nil {
				return fmt.Errorf("blogengine: decode config: %w", err)
			}

			err = run(stdout, config, preview, uploadPreview)
			if err != nil {
				return fmt.Errorf("blogengine: %w", err)
			}
			return nil
		},
	))
}

func chdirWebRoot(configFile string) error {
	// find and change to web root
	for {
		_, err := os.Stat(configFile)
		if err != nil {
			if errors.Is(err, os.ErrNotExist) {
				_, err = os.Stat(".git")
				if err == nil {
					return fmt.Errorf("config file not found, not checking past repo root")
				} else if errors.Is(err, os.ErrNotExist) {
					if dir, _ := os.Getwd(); dir == "/" {
						return fmt.Errorf("at system root /, config file not found")
					}
					os.Chdir("..")

					continue
				} else {
					return fmt.Errorf("error checking for git root: %w", err)
				}
			} else {
				return fmt.Errorf("error checking for config file: %w", err)
			}
		}
		break
	}

	return nil
}

type Config struct {
	Render struct {
		BaseURL     string `json:"baseUrl"`
		Destination string `json:"dst"`
		GTM         string `json:"gtm"`
		Source      string `json:"src"`
		Style       string `json:"style"`
	} `json:"render"`
	Firebase ConfigFirebase `json:"firebase"`
}

type ConfigFirebase struct {
	SiteID string `json:"site"`

	Headers []struct {
		Glob    string            `json:"glob"`
		Headers map[string]string `json:"headers"`
	} `json:"headers"`
	Redirects []struct {
		Glob       string `json:"glob"`
		Location   string `json:"location"`
		StatusCode int    `json:"code"`
	} `json:"redirects"`
}

func run(stdout io.Writer, conf Config, preview, uploadPreview bool) error {
	ctx := context.Background()
	ctx, done := signal.NotifyContext(ctx, syscall.SIGINT, syscall.SIGTERM)
	defer done()

	fi, err := os.Stat(conf.Render.Source)
	if err != nil {
		return fmt.Errorf("stat source: %w", err)
	}

	compact := conf.Render.Style == "compact"
	var rendered map[string]*bytes.Buffer
	if !fi.IsDir() {
		return fmt.Errorf("expected directory as src")
	}
	rendered, err = renderMulti(ctx, conf.Render.Source, conf.Render.GTM, conf.Render.BaseURL, compact)
	if err != nil {
		return fmt.Errorf("render: %w", err)
	}

	if preview {
		lg := slog.New(jsonlog.New(slog.LevelInfo, stdout))
		lookup := make(map[string]string)
		for p := range rendered {
			lookup[canonicalPathFromRelPath(p)] = p
		}
		ts := time.Now()
		mux := yhttp.New()
		mux.Handle("GET /", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			p, ok := lookup[r.URL.Path]
			lg.LogAttrs(r.Context(), slog.LevelInfo, "serve page", slog.String("path", r.URL.Path), slog.String("lookup", p))
			if !ok {
				http.Error(w, "not found", http.StatusNotFound)
				return
			}
			buf, ok := rendered[p]
			if !ok {
				http.Error(w, "not found", http.StatusNotFound)
				return
			}
			http.ServeContent(w, r, p, ts, bytes.NewReader(buf.Bytes()))
		}))

		var lis net.Listener
		lis, err = net.Listen("tcp4", ":0")
		if err != nil {
			return fmt.Errorf("listen on a port: %w", err)
		}
		defer lis.Close()
		lg.Info("listening", "addr", fmt.Sprintf("http://127.0.0.1:%d/", lis.Addr().(*net.TCPAddr).Port))
		svr := &http.Server{
			Handler: mux,
		}
		ctx, cancel := context.WithCancel(ctx)
		go func() {
			defer cancel()
			err := svr.Serve(lis)
			if err != nil && !errors.Is(err, http.ErrServerClosed) {
				lg.Error("unexpected server shutdown", "err", err)
			}
		}()
		<-ctx.Done()
		shutCtx := context.Background()
		shutCtx, cancel = context.WithTimeout(shutCtx, 5*time.Second)
		defer cancel()
		svr.Shutdown(shutCtx)
		return nil
	}

	if conf.Render.Destination != "" {
		err = writeRendered(ctx, stdout, conf.Render.Destination, rendered)
		if err != nil {
			return fmt.Errorf("write rendered: %w", err)
		}
	}
	if conf.Firebase.SiteID != "" {
		err = uploadFirebase(ctx, stdout, conf.Firebase, rendered, uploadPreview)
		if err != nil {
			return fmt.Errorf("upload to firebase: %w", err)
		}
	}

	return nil
}
