package main

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net"
	"net/http"
	"time"

	"go.seankhliao.com/mono/jsonlog"
	"go.seankhliao.com/mono/yhttp"
)

func servePreview(ctx context.Context, stdout io.Writer, rendered map[string]*bytes.Buffer) error {
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
	lis, err := net.Listen("tcp4", ":0")
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
