package basehttp

import (
	"context"
	"errors"
	"flag"
	"log/slog"
	"net"
	"net/http"
	"os"
	"time"
	_ "time/tzdata"

	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.seankhliao.com/mono/observability"
	_ "golang.org/x/crypto/x509roots/fallback"
	"golang.org/x/net/http2"
	"golang.org/x/net/http2/h2c"
)

type Config struct {
	Address string
}

func (c *Config) SetFlags(fset *flag.FlagSet) {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	fset.StringVar(&c.Address, "http.addr", ":"+port, "http server address")
}

type HTTP struct {
	O      *observability.O
	Mux    *http.ServeMux
	Server *http.Server
	Client *http.Client
}

func New(ctx context.Context, o *observability.O, c *Config) *HTTP {
	o = o.Component("basehttp")
	mux := http.NewServeMux()
	h2Server := &http2.Server{}
	server := &http.Server{
		Addr:              c.Address,
		Handler:           otelhttp.NewHandler(h2c.NewHandler(mux, h2Server), "serve http"),
		ReadHeaderTimeout: 10 * time.Second,
		ErrorLog:          slog.NewLogLogger(o.H, slog.LevelWarn),
	}
	client := &http.Client{
		Transport: otelhttp.NewTransport(http.DefaultTransport),
	}
	return &HTTP{
		O:      o,
		Mux:    mux,
		Server: server,
		Client: client,
	}
}

func (h *HTTP) Run(ctx context.Context) error {
	h.O.L.LogAttrs(ctx, slog.LevelInfo, "starting listen", slog.String("address", h.Server.Addr))
	lis, err := net.Listen("tcp", h.Server.Addr)
	if err != nil {
		return h.O.Err(ctx, "listen locally", err)
	}
	go func() {
		<-ctx.Done()
		err := h.Server.Shutdown(context.Background())
		if err != nil {
			h.O.Err(ctx, "error closing server", err, slog.String("address", h.Server.Addr))
		}
	}()

	h.O.L.LogAttrs(ctx, slog.LevelInfo, "starting server")
	err = h.Server.Serve(lis)
	if err != nil && !errors.Is(err, http.ErrServerClosed) {
		return h.O.Err(ctx, "error serving http", err)
	}
	return nil
}
