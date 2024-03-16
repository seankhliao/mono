package serve

import (
	"context"
	"io/fs"
	"log/slog"
	"net/http"

	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.seankhliao.com/mono/cmd/mono/ghdefaults"
	"go.seankhliao.com/mono/httpencoding"
)

func NewServer(ctx context.Context, c Config, lg *slog.Logger, fsys fs.FS) (*http.Server, error) {
	mux := http.NewServeMux()

	// authn
	// mux.Handle("GET /auth/{$}")
	// mux.Handle("GET /auth/login")
	// mux.Handle("GET /auth/register")
	// mux.Handle("GET /auth/logout")

	// mux.Handle("GET /earbug/{$}")
	// mux.Handle("GET /earbug/artists")
	// mux.Handle("GET /earbug/callback")
	// mux.Handle("GET /earbug/export")
	// mux.Handle("GET /earbug/playbacks")
	// mux.Handle("GET /earbug/tracks")

	ghdefaults.Register(c.GHDefaults, mux)

	// mux.Handle("GET /ytfeed/feed/{feed}")
	// mux.Handle("GET /ytfeed/lookup")

	httpSvr := &http.Server{
		Addr:    c.HTTP.Addr,
		Handler: otelhttp.NewHandler(httpencoding.Handler(mux), "handle http"),
	}

	return httpSvr, nil
}
