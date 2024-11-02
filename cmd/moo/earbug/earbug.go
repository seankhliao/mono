package earbug

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"net/http"
	"time"

	"github.com/zmb3/spotify/v2"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/trace"
	"go.seankhliao.com/mono/httpencoding"
	"go.seankhliao.com/mono/yrun"
	"gocloud.dev/blob"
	_ "gocloud.dev/blob/gcsblob"
	"golang.org/x/oauth2"
)

type Config struct {
	Host string

	Oauth2 oauth2.Config

	Key string

	UpdateFreq time.Duration
}

func Register(a *App, r yrun.HTTPRegistrar) {
	r.Pattern("GET", a.host, "/", httpencoding.Handler(http.HandlerFunc(a.handleIndex)))
	r.Pattern("GET", a.host, "/artists", httpencoding.Handler(http.HandlerFunc(a.handleArtists)))
	r.Pattern("GET", a.host, "/playbacks", httpencoding.Handler(http.HandlerFunc(a.handlePlaybacks)))
	r.Pattern("GET", a.host, "/tracks", httpencoding.Handler(http.HandlerFunc(a.handleTracks)))
	r.Pattern("GET", a.host, "/auth/begin", a.Auth(http.HandlerFunc(a.authBegin)))
	r.Pattern("GET", a.host, "/auth/callback", a.Auth(http.HandlerFunc(a.authCallback)))
}

type App struct {
	o yrun.O11y

	// New
	http  *http.Client
	spot  *spotify.Client
	store *yrun.Store[*Store]

	// inserted
	Auth func(http.Handler) http.Handler

	// config
	host       string
	bkt        *blob.Bucket
	dataKey    string
	oauth2     oauth2.Config
	updateFreq time.Duration
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
		host:       c.Host,
		bkt:        bkt,
		dataKey:    c.Key,
		oauth2:     c.Oauth2,
		updateFreq: c.UpdateFreq,
	}

	ctx, span := o.T.Start(ctx, "initData")
	defer span.End()

	store, err := yrun.NewStore[Store](ctx, bkt, c.Key, func() *Store {
		return &Store{
			Auth:      &Auth{},
			Playbacks: make(map[string]*Playback),
			Tracks:    make(map[string]*Track),
		}
	})
	if err != nil {
		return nil, fmt.Errorf("init data.store.Data: %w", err)
	}
	a.store = store

	var token oauth2.Token
	a.store.RDo(func(s *Store) {
		err = json.Unmarshal(s.Auth.Token, &token)
	})
	if err != nil {
		a.Err(ctx, "get token from storage", err)
	}

	httpClient := &http.Client{Transport: otelhttp.NewTransport(http.DefaultTransport)}
	ctx = context.WithValue(ctx, oauth2.HTTPClient, httpClient)
	a.spot = spotify.New(a.oauth2.Client(ctx, &token))
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

func (a *App) Update() error {
	for {
		ctx := context.Background()
		ctx, cancel := context.WithTimeout(ctx, a.updateFreq)
		a.update(ctx)
		cancel()

		time.Sleep(a.updateFreq)
	}
}

func ptr[T any](v T) *T {
	return &v
}
