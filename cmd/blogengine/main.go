package main

import (
	"bytes"
	_ "embed"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"

	"go.seankhliao.com/mono/cueconf"
	"go.seankhliao.com/mono/ycli"
)

//go:embed schema.cue
var configSchema string

func main() {
	var configFile string
	ycli.OSExec(ycli.New(
		"blogengine",
		"markdown to html renderer, with firebase integration",
		func(fs *flag.FlagSet) {
			fs.StringVar(&configFile, "config", "blogengine.cue", "path to config file")
		},
		func(stdout, _ io.Writer) error {
			err := chdirWebRoot(configFile)
			if err != nil {
				return fmt.Errorf("blogengine: %w", err)
			}

			config, err := cueconf.ForFile[Config](configSchema, configFile)
			if err != nil {
				return fmt.Errorf("blogengine: decode config: %w", err)
			}

			err = run(stdout, config)
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

func run(stdout io.Writer, conf Config) error {
	fi, err := os.Stat(conf.Render.Source)
	if err != nil {
		return fmt.Errorf("stat source: %w", err)
	}

	compact := conf.Render.Style == "compact"
	var rendered map[string]*bytes.Buffer
	if !fi.IsDir() {
		rendered, err = renderSingle(conf.Render.Source, compact)
	} else {
		rendered, err = renderMulti(conf.Render.Source, conf.Render.GTM, conf.Render.BaseURL, compact)
	}
	if err != nil {
		return fmt.Errorf("render: %w", err)
	}

	if conf.Render.Destination != "" {
		err = writeRendered(stdout, conf.Render.Destination, rendered)
		if err != nil {
			return fmt.Errorf("write rendered: %w", err)
		}
	}
	if conf.Firebase.SiteID != "" {
		err = uploadFirebase(stdout, conf.Firebase, rendered)
		if err != nil {
			return fmt.Errorf("upload to firebase: %w", err)
		}
	}

	return nil
}
