package main

import (
	"bytes"
	"context"
	_ "embed"
	"fmt"
	"log/slog"
	"os"

	"go.seankhliao.com/mono/jsonlog"
	"go.seankhliao.com/mono/webstyle"
)

func main() {
	lh := jsonlog.New(slog.LevelInfo, os.Stderr)
	lg := slog.New(lh)
	ctx := context.Background()

	err := run(ctx, lg, os.Args)
	if err != nil {
		slog.LogAttrs(ctx, slog.LevelError, "run", slog.String("error", err.Error()))
		os.Exit(1)
	}
}

func run(ctx context.Context, lg *slog.Logger, args []string) error {
	conf, err := newConfig(ctx, lg, args)
	if err != nil {
		return err
	}

	var render webstyle.Renderer
	lg.LogAttrs(ctx, slog.LevelDebug, "setting renderer style", slog.String("style", conf.Render.Style))
	switch conf.Render.Style {
	case "compact":
		render = webstyle.NewRenderer(webstyle.TemplateCompact)
	case "full":
		render = webstyle.NewRenderer(webstyle.TemplateFull)
	default:
		return fmt.Errorf("unknown renderer style: %s", conf.Render.Style)
	}

	fi, err := os.Stat(conf.Render.Source)
	if err != nil {
		lg.LogAttrs(ctx, slog.LevelError, "stat source", slog.String("src", conf.Render.Source), slog.String("error", err.Error()))
		return err
	}
	var rendered map[string]*bytes.Buffer
	if !fi.IsDir() {
		rendered, err = renderSingle(ctx, lg, render, conf.Render.Source)
	} else {
		rendered, err = renderMulti(ctx, lg, render, conf.Render.Source, conf.Render.GTM, conf.Render.BaseURL)
	}
	if err != nil {
		lg.LogAttrs(ctx, slog.LevelError, "render", slog.String("src", conf.Render.Source), slog.String("error", err.Error()))
		return err
	}

	if conf.Render.Destination != "" {
		err = writeRendered(ctx, lg, conf.Render.Destination, rendered)
		if err != nil {
			lg.LogAttrs(ctx, slog.LevelError, "write rendered output", slog.String("dst", conf.Render.Destination), slog.String("error", err.Error()))
			return err
		}
	}
	if conf.Firebase.SiteID != "" {
		err = uploadFirebase(ctx, lg, conf.Firebase, rendered)
		if err != nil {
			lg.LogAttrs(ctx, slog.LevelError, "upload to firebase", slog.String("error", err.Error()))
			return err
		}
	}

	return nil
}
