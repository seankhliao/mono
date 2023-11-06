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
			m.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
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

				if r.Method != http.MethodGet {
					http.Error(w, http.StatusText(http.StatusMethodNotAllowed), http.StatusMethodNotAllowed)
					return
				}
				http.ServeContent(w, r, "index.html", t0, bytes.NewReader(index))
			})
			return nil, nil
		},
	})
}
