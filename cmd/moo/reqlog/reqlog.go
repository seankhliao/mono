package reqlog

import (
	"log/slog"
	"net/http"

	"go.seankhliao.com/mono/yrun"
)

type Config struct {
	Host string
}

type App struct {
	config Config
	o      yrun.O11y
}

func New(c Config, o yrun.O11y) (*App, error) {
	return &App{
		config: c,
		o:      o.Sub("reqlog"),
	}, nil
}

func (a *App) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	a.o.L.LogAttrs(r.Context(), slog.LevelInfo, "received request",
		slog.String("http.method", r.Method),
		slog.String("http.proto", r.Proto),
		slog.String("http.host", r.Host),
		slog.String("http.url", r.URL.String()),
		slog.String("http.request_uri", r.RequestURI),
		slog.String("http.remote_addr", r.RemoteAddr),
		slog.Any("http.headers", r.Header),
		slog.Any("http.trailers", r.Trailer),
	)
}

func Register(a *App, r yrun.HTTPRegistrar) {
	r.Pattern("", a.config.Host, "/", a)
}
