package main

import (
	"context"
	_ "embed"
	"flag"
	"fmt"
	"log/slog"
	"os"
	"time"

	"cuelang.org/go/cue"
	"cuelang.org/go/cue/cuecontext"
)

//go:embed schema.cue
var configSchema string

func newConfig(ctx context.Context, lg *slog.Logger, configFile string) (Config, error) {
	var conf Config
	cuectx := cuecontext.New()
	confUnified := cuectx.CompileString(configSchema)

	lg.LogAttrs(ctx, slog.LevelDebug, "read config", slog.String("file", configFile))
	configGiven, err := os.ReadFile(configFile)
	if err != nil {
		return Config{}, fmt.Errorf("read %s: %w", configFile, err)
	}

	confGiven := cuectx.CompileBytes(configGiven)
	confPath := cue.ParsePath("config")
	err = confUnified.FillPath(confPath, confGiven).LookupPath(confPath).Decode(&conf)
	if err != nil {
		return Config{}, fmt.Errorf("decode unified config: %w", err)
	}

	return conf, nil
}

type Config struct {
	MaxAge          time.Duration         `json:"maxAge"`
	RefreshInterval time.Duration         `json:"refresh"`
	Feeds           map[string]ConfigFeed `json:"feeds"`

	// flags

	lookup []string
	mode   string
	file   string
}

func (c *Config) SetFlags(fset *flag.FlagSet) {
	fset.StringVar(&c.mode, "mode", "serve", "lookup|serve")
	fset.Func("lookup", "(repeatable) username to lookup", func(s string) error {
		c.lookup = append(c.lookup, s)
		return nil
	})

	fset.Func("config", "path to config file", func(s string) error {
		cuectx := cuecontext.New()
		confUnified := cuectx.CompileString(configSchema)
		configGiven, err := os.ReadFile(s)
		if err != nil {
			return fmt.Errorf("read file %s: %w", s, err)
		}

		confGiven := cuectx.CompileBytes(configGiven)
		confUnified = confUnified.Unify(confGiven)
		err = confUnified.Decode(&c)
		if err != nil {
			return fmt.Errorf("unify config %s with schema: %w", s, err)
		}
		return nil
	})
}

type ConfigFeed struct {
	Name        string                   `json:"name"`
	Description string                   `json:"description"`
	Exclude     map[string]string        `json:"exclude"`
	Channels    map[string]ConfigChannel `json:"channels"`
}
type ConfigChannel struct {
	Title     string `json:"title"`
	ChannelID string `json:"channel_id"`
	UploadsID string `json:"uploads_id"`
}
