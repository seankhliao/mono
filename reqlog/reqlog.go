package reqlog

import (
	"context"
	"encoding/json/jsontext"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"strings"

	"go.seankhliao.com/mono/yhttp"
	"go.seankhliao.com/mono/yo11y"
)

func Register(a *App, r yhttp.Registrar) {
	r.Pattern("GET", a.config.Host, "/robots.txt", a.robots)
	r.Pattern("", a.config.Host, "/", a.ServeHTTP)
}

type Config struct {
	Host string
}

type App struct {
	o      yo11y.O11y
	config Config
}

func New(ctx context.Context, c Config, o yo11y.O11y) (*App, error) {
	return &App{
		config: c,
		o:      o.Sub("reqlog"),
	}, nil
}

func (a *App) ServeHTTP(rw http.ResponseWriter, r *http.Request) {
	rw.Header().Set("x-robots-tag", "none")
	rw.Header().Set("content-type", "text/plain")
	fmt.Fprintln(rw, "ok")

	b, _ := io.ReadAll(r.Body)
	body := slog.String("http.body", string(b))
	if strings.HasPrefix(r.Header.Get("content-type"), "application/json") {
		body = slog.Any("http.body", jsontext.Value(b))
	}

	a.o.L.LogAttrs(r.Context(), slog.LevelInfo, "received request",
		slog.String("http.method", r.Method),
		slog.String("http.proto", r.Proto),
		slog.String("http.host", r.Host),
		slog.String("http.url", r.URL.String()),
		slog.String("http.request_uri", r.RequestURI),
		slog.String("http.remote_addr", r.RemoteAddr),
		slog.Any("http.headers", r.Header),
		slog.Any("http.trailers", r.Trailer),
		body,
	)
}

const robotsTxt = `
User-agent: *
Disallow: /
`

func (a *App) robots(rw http.ResponseWriter, r *http.Request) {
	fmt.Fprint(rw, robotsTxt)
}
