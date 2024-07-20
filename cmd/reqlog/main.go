package main

import (
	"context"
	"log/slog"
	"net/http"

	"go.seankhliao.com/mono/framework"
	"go.seankhliao.com/mono/observability"
)

func main() {
	framework.Run(framework.Config{
		Start: func(ctx context.Context, o *observability.O, sm *http.ServeMux) (cleanup func(), err error) {
			sm.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
				o.L.InfoContext(r.Context(), "got request", slog.Group("http",
					slog.String("method", r.Method),
					slog.String("proto", r.Proto),
					slog.String("host", r.Host),
					slog.String("", r.URL.String()),
					slog.String("request_uri", r.RequestURI),
					slog.String("remote_addr", r.RemoteAddr),
					slog.Any("headers", r.Header),
					slog.Any("trailers", r.Trailer),
				))
			})
			return nil, nil
		},
	})
}
