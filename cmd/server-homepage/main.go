package main

import (
	"bytes"
	"context"
	"log/slog"
	"net/http"
	"time"

	"github.com/maragudk/gomponents"
	"github.com/maragudk/gomponents/html"
	"go.seankhliao.com/mono/framework"
	"go.seankhliao.com/mono/httpencoding"
	"go.seankhliao.com/mono/observability"
	"go.seankhliao.com/mono/webstyle"
	"go.seankhliao.com/mono/webstyle/webstatic"
)

func main() {
	name := "justia"
	framework.Run(framework.Config{
		Start: func(ctx context.Context, o *observability.O, m *http.ServeMux) (func(), error) {
			t0 := time.Now()

			ro := webstyle.NewOptions(name, name, []gomponents.Node{
				html.H3(html.Em(gomponents.Text("inter")), gomponents.Text("webs")),
				html.P(
					html.Em(gomponents.Text("Congratulations")),
					gomponents.Text("You've found a server on the internet."),
				),
			})
			var buf bytes.Buffer
			webstyle.Structured(&buf, ro)

			webstatic.Register(m)
			m.Handle("GET /{$}", httpencoding.Handler(handle(o, t0, "index.html", buf.Bytes())))
			return nil, nil
		},
	})
}

func handle(o *observability.O, t0 time.Time, filename string, index []byte) http.Handler {
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

		http.ServeContent(w, r, filename, t0, bytes.NewReader(index))
	})
}
