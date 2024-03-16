package serve

import (
	"context"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"log/slog"
	"net/http"
	"time"
)

func Run(ctx context.Context, env, args []string, fsys fs.FS, stdout, stderr io.Writer) error {
	conf, err := NewConfig(env, args)
	if err != nil {
		return fmt.Errorf("parsing config: %w", err)
	}

	shutdown, lg, err := NewTelemetry(ctx, conf, stdout)
	if err != nil {
		return fmt.Errorf("setup telemetry: %w", err)
	}
	defer shutdown()

	svr, err := NewServer(ctx, conf, lg, fsys)
	if err != nil {
		lg.Error("create server", "err", err)
		return fmt.Errorf("creating server: %w", err)
	}

	err = RunServer(ctx, lg, svr)
	if err != nil {
		lg.Error("run server", "err", err)
		return fmt.Errorf("run server: %w", err)
	}

	return nil
}

func RunServer(ctx context.Context, lg *slog.Logger, svr *http.Server) error {
	errc := make(chan error, 1)
	go func() {
		<-ctx.Done()
		ctx := context.Background()
		ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
		defer cancel()
		svr.Shutdown(ctx)
	}()
	go func() {
		lg.Info("starting http server", "addr", svr.Addr)
		err := svr.ListenAndServe()
		if err != nil && !errors.Is(err, http.ErrServerClosed) {
			errc <- err
			return
		}
		errc <- nil
	}()
	err := <-errc
	if err != nil {
		return fmt.Errorf("unclean shutdown: %w", err)
	}
	return nil
}
