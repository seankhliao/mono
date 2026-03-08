package main

import (
	"context"
	"flag"
	"io"
	"io/fs"
	"log/slog"
	"net/http"

	"go.seankhliao.com/mono/run"
)

func main() {
	run.OSExec(&run.CommandGroup{
		Name: "nerys-monolith",
		Desc: "a bundle of all the servers to run on nerys.",
		Subs: []run.Commander{
			&run.CommandBasic[ServeConfig]{
				Name:  "serve",
				Desc:  "serve the web",
				Flags: (*ServeConfig).Flags,
				Do:    (*ServeConfig).Do,
			},
		},
	})
}

type ServeConfig struct {
	LogLevel slog.LevelVar

	h HTTP
}

func (s *ServeConfig) Flags(fset *flag.FlagSet) error {
	fset.TextVar(&s.LogLevel, "log.level", &s.LogLevel, "log level")

	s.h.Flags(fset)
	return nil
}

func (s *ServeConfig) Do() run.Runner {
	return func(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
		return s.Run(ctx, stdin, stdout, stderr, fsys)
	}
}

func (s *ServeConfig) Run(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	logHandler := slog.NewTextHandler(stderr, &slog.HandlerOptions{
		Level: &s.LogLevel,
	})
	register := func(mux *http.ServeMux) {
		registerDebug(mux)
	}
	runner := s.h.Runner(logHandler, register)

	return runner(ctx, stdin, stdout, stderr, fsys)
}
