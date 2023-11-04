package main

import (
	"context"
	_ "embed"
	"flag"
	"fmt"
	"log/slog"
	"net/url"
	"os"

	"cuelang.org/go/cue/cuecontext"
)

//go:embed config_default.cue
var configDefault string

func newConfig(ctx context.Context, lg *slog.Logger, args []string) (Config, error) {
	fset := flag.NewFlagSet("blogengine", flag.ExitOnError)
	var v int
	fset.IntVar(&v, "v", 0, "logging verbosity")
	configFile := "blogengine.cue"
	fset.Func("config", "path to config file:blogengine.cue", func(s string) error {
		u, err := url.Parse(s)
		if err != nil {
			return err
		} else if u.Scheme != "file" {
			return fmt.Errorf("unknown scheme: %s", u.Scheme)
		}
		if u.Opaque != "" {
			configFile = u.Opaque
		} else if u.Path != "" {
			configFile = u.Path
		} else {
			return fmt.Errorf("path not found: %s", u)
		}
		return nil
	})
	fset.Parse(args[1:])

	var conf Config
	cuectx := cuecontext.New()
	confUnified := cuectx.CompileString(configDefault)

	lg.LogAttrs(ctx, slog.LevelDebug, "rad config", slog.String("file", configFile))
	configGiven, err := os.ReadFile(configFile)
	if err != nil {
		return Config{}, fmt.Errorf("read %s: %w", configFile, err)
	}

	confGiven := cuectx.CompileBytes(configGiven)
	confUnified = confUnified.Unify(confGiven)
	err = confUnified.Decode(&conf)
	if err != nil {
		return Config{}, fmt.Errorf("decode unified config: %w", err)
	}

	if conf.Render.Destination == "" && conf.Firebase.SiteID == "" {
		return Config{}, fmt.Errorf("no output (dst|firebase.site) given")
	}
	return conf, nil
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
