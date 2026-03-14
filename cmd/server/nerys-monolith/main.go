package main

import (
	"context"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"log/slog"
	"net/http"
	"strings"

	"go.seankhliao.com/mono/run"
)

func main() {
	run.OSExec(run.Group(
		"nerys-monolith",
		"a bundle of all the servers to run on nerys.",
		run.Simple("serve", "run a http server", &ServeConfig{}),
	))
}

var _ run.Simpler = &ServeConfig{}

type ServeConfig struct {
	logLevel slog.LevelVar
	h        run.HTTP
}

func (s *ServeConfig) Flags(fset *flag.FlagSet, args **[]string) error {
	fset.TextVar(&s.logLevel, "log.level", &s.logLevel, "log level")

	s.h.HostPolicy = hostPolicy

	s.h.Flags(fset)
	return nil
}

func (s *ServeConfig) Run(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	logHandler := slog.NewTextHandler(stderr, &slog.HandlerOptions{
		Level: &s.logLevel,
	})
	register := func(mux *http.ServeMux) {
		mux.HandleFunc("GET /{$}", func(w http.ResponseWriter, r *http.Request) {
			fmt.Fprintln(w, "hello world")
		})
	}

	runner := s.h.Runner(logHandler, register)
	return runner(ctx, stdin, stdout, stderr, fsys)
}

func hostPolicy(ctx context.Context, host string) error {
	h, ok := strings.CutSuffix(host, ".liao.dev")
	if !ok {
		return fmt.Errorf("not a public address: %s", host)
	}
	h, _ = strings.CutSuffix(h, ".nerys")
	if strings.Contains(h, ".") {
		return fmt.Errorf("not an allowed subdomain: %s", host)
	}
	return nil
}
