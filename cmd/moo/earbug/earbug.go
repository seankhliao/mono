package earbug

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"net/http"
	"sync/atomic"
	"time"

	"github.com/zmb3/spotify/v2"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/trace"
	"go.seankhliao.com/mono/cmd/moo/earbug/earbugv4"
	"go.seankhliao.com/mono/httpencoding"
	"go.seankhliao.com/mono/yrun"
	"gocloud.dev/blob"
	_ "gocloud.dev/blob/gcsblob"
	"golang.org/x/oauth2"
)

type Config struct {
	Host string

	Key     string
	AuthURL string

	UpdateFreq time.Duration
}

func Register(a *App, r yrun.HTTPRegistrar) {
	r.Pattern("GET", a.host, "/", httpencoding.Handler(http.HandlerFunc(a.handleIndex)))
	r.Pattern("GET", a.host, "/artists", httpencoding.Handler(http.HandlerFunc(a.handleArtists)))
	r.Pattern("GET", a.host, "/playbacks", httpencoding.Handler(http.HandlerFunc(a.handlePlaybacks)))
	r.Pattern("GET", a.host, "/tracks", httpencoding.Handler(http.HandlerFunc(a.handleTracks)))
	r.Pattern("GET", a.host, "/api/auth", http.HandlerFunc(a.hAuthorize))
	r.Pattern("GET", a.host, "/auth/callback", http.HandlerFunc(a.hAuthCallback))
}

type App struct {
	o yrun.O11y

	// New
	http  *http.Client
	spot  *spotify.Client
	store *yrun.Store[*earbugv4.Store]

	// config
	host    string
	bkt     *blob.Bucket
	dataKey string
	authURL string

	authState atomic.Pointer[AuthState]
}

func New(c Config, bkt *blob.Bucket, o yrun.O11y) (*App, error) {
	ctx := context.Background()

	a := &App{
		o: yrun.O11y{
			T: otel.Tracer("earbug"),
			M: otel.Meter("earbug"),
			L: o.L.WithGroup("earbug"),
			H: o.H.WithGroup("earbug"),
		},
		http: &http.Client{
			Transport: otelhttp.NewTransport(http.DefaultTransport),
		},
		host:    c.Host,
		bkt:     bkt,
		dataKey: c.Key,
		authURL: c.AuthURL,
	}

	ctx, span := o.T.Start(ctx, "initData")
	defer span.End()

	store, err := yrun.NewStore[*earbugv4.Store](ctx, bkt, c.Key)
	if err != nil {
		return nil, fmt.Errorf("init data.store.Data: %w", err)
	}
	a.store = store

	var token oauth2.Token
	if a.store.Data.Auth != nil && len(a.store.Data.Auth.Token) > 0 {
		rawToken := a.store.Data.Auth.Token // new value
		err = json.Unmarshal(rawToken, &token)
		if err != nil {
			return nil, a.Err(ctx, "unmarshal oauth token", err)
		}
	} else {
		o.L.LogAttrs(ctx, slog.LevelWarn, "no auth token found")
	}

	httpClient := &http.Client{Transport: otelhttp.NewTransport(http.DefaultTransport)}
	ctx = context.WithValue(ctx, oauth2.HTTPClient, httpClient)
	as := NewAuthState(a.store.Data.Auth.ClientId, a.store.Data.Auth.ClientSecret, "")
	httpClient = as.conf.Client(ctx, &token)
	a.spot = spotify.New(httpClient)

	return a, nil
}

func (a *App) Err(ctx context.Context, msg string, err error, attrs ...slog.Attr) error {
	a.o.L.LogAttrs(ctx, slog.LevelError, msg,
		append(attrs, slog.String("error", err.Error()))...,
	)
	if span := trace.SpanFromContext(ctx); span.SpanContext().IsValid() {
		span.RecordError(err)
		span.SetStatus(codes.Error, msg)
	}

	return fmt.Errorf("%s: %w", msg, err)
}

func (a *App) HTTPErr(ctx context.Context, msg string, err error, rw http.ResponseWriter, code int, attrs ...slog.Attr) {
	err = a.Err(ctx, msg, err, attrs...)
	http.Error(rw, err.Error(), code)
}
