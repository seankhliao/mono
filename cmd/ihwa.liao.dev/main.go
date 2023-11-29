package main

import (
	"bytes"
	"context"
	_ "embed"
	"fmt"
	"log/slog"
	"net/http"
	"time"

	"go.seankhliao.com/mono/framework"
	"go.seankhliao.com/mono/httpencoding"
	"go.seankhliao.com/mono/observability"
	"go.seankhliao.com/mono/webstyle"
)

//go:embed index.md
var rawIndex []byte

func main() {
	framework.Run(framework.Config{
		Start: func(ctx context.Context, o *observability.O, m *http.ServeMux) (func(), error) {
			t0 := time.Now()
			index, err := webstyle.NewRenderer(webstyle.TemplateCompact).RenderBytes(rawIndex, webstyle.Data{})
			if err != nil {
				return nil, fmt.Errorf("render index: %w", err)
			}
			m.Handle("GET /{$}", httpencoding.Handler(handleIndex(o, t0, index)))
			return nil, nil
		},
	})
}

func handleIndex(o *observability.O, t0 time.Time, index []byte) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		ctx, span := o.T.Start(r.Context(), "handle request")
		defer span.End()

		o.L.LogAttrs(ctx, slog.LevelDebug, "handle request", slog.Group("http.request",
			slog.String("proto", r.Proto),
			slog.String("method", r.Method),
			slog.String("host", r.Host),
			slog.String("path", r.URL.Path),
			slog.String("remote", r.RemoteAddr),
			slog.Any("headers", r.Header),
		))

		http.ServeContent(w, r, "index.html", t0, bytes.NewReader(index))
	})
}
