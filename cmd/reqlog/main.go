package main

import (
	"context"
	"log/slog"
	"net/http"
	"net/http/httputil"

	"go.seankhliao.com/mono/framework"
	"go.seankhliao.com/mono/observability"
)

func main() {
	framework.Run(framework.Config{
		Start: func(ctx context.Context, o *observability.O, sm *http.ServeMux) (cleanup func(), err error) {
			sm.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
				b, err := httputil.DumpRequest(r, false)
				if err != nil {
					o.L.ErrorContext(r.Context(), "dump request", "err", err)
				}
				o.L.InfoContext(r.Context(), "got request", slog.String("req", string(b)))
			})
			return nil, nil
		},
	})
}
