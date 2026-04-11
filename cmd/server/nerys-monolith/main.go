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

	"go.seankhliao.com/mono/githost"
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

	githost githost.GitHost
}

func (s *ServeConfig) Flags(fset *flag.FlagSet, args **[]string) error {
	s.h.HostPolicy = hostPolicy
	s.h.Flags(fset)

	fset.TextVar(&s.logLevel, "log.level", &s.logLevel, "log level")

	err := s.githost.Flags(fset)
	if err != nil {
		return fmt.Errorf("register githost flags: %w", err)
	}

	return nil
}

func (s *ServeConfig) Run(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	logHandler := slog.NewTextHandler(stderr, &slog.HandlerOptions{
		Level: &s.logLevel,
	})
	log := slog.New(logHandler)
	register := func(mux *http.ServeMux) {
		mux.HandleFunc("GET /{$}", func(w http.ResponseWriter, r *http.Request) {
			fmt.Fprintln(w, "hello world")
		})

		err := s.githost.Register(mux, logHandler)
		if err != nil {
			log.Error("register githost", slog.String("err", err.Error()))
		}
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
