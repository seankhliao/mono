package main

import (
	_ "embed"
	"flag"
	"fmt"
	"os"
	"regexp"
	"time"

	"cuelang.org/go/cue"
	"cuelang.org/go/cue/cuecontext"
)

var (
	//go:embed schema.cue
	configSchema string

	//go:embed config.cue
	defaultConfig string
)

type Config struct {
	MaxAge          time.Duration         `json:"maxAge"`
	RefreshInterval time.Duration         `json:"refresh"`
	Feeds           map[string]ConfigFeed `json:"feeds"`

	// flags

	lookup []string
	mode   string
}

func (c *Config) SetFlags(fset *flag.FlagSet) {
	fset.StringVar(&c.mode, "mode", "serve", "lookup|serve")
	fset.Func("lookup", "(repeatable) username to lookup", func(s string) error {
		c.lookup = append(c.lookup, s)
		return nil
	})

	fset.Func("config", "path to config file", func(s string) error {
		configGiven, err := os.ReadFile(s)
		if err != nil {
			return fmt.Errorf("read file %s: %w", s, err)
		}

		return c.setConfig(configGiven)
	})
}

func (c *Config) setConfig(configGiven []byte) error {
	cuectx := cuecontext.New()
	confGiven := cuectx.CompileBytes(configGiven)

	confPath := cue.ParsePath("config")
	confUnified := cuectx.CompileString(configSchema)
	confUnified = confUnified.FillPath(confPath, confGiven)
	confUnified = confUnified.LookupPath(confPath)
	err := confUnified.Decode(&c)
	if err != nil {
		return fmt.Errorf("unify config with schema: %w", err)
	}

	for feed, fc := range c.Feeds {
		m := make(map[string]*regexp.Regexp)
		for name, expr := range c.Feeds[feed].Exclude {
			r, err := regexp.Compile(expr)
			if err != nil {
				return fmt.Errorf("compile regex for feed=%v exlude=%v err=%w", feed, name, err)
			}
			m[name] = r
		}
		fc.exclude = m
		c.Feeds[feed] = fc
	}

	return nil
}

type ConfigFeed struct {
	Name        string                   `json:"name"`
	Description string                   `json:"description"`
	Channels    map[string]ConfigChannel `json:"channels"`
	Exclude     map[string]string        `json:"exclude"`
	exclude     map[string]*regexp.Regexp
}
type ConfigChannel struct {
	Title     string `json:"title"`
	ChannelID string `json:"channel_id"`
	UploadsID string `json:"uploads_id"`
}
