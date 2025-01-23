package earbug

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/google/cel-go/cel"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel/metric"
	"go.seankhliao.com/mono/auth"
	earbugv5 "go.seankhliao.com/mono/earbug/v5"
	"go.seankhliao.com/mono/httpencoding"
	"go.seankhliao.com/mono/yhttp"
	"go.seankhliao.com/mono/yo11y"
	"go.seankhliao.com/mono/ystore"
	"gocloud.dev/blob"
	"golang.org/x/oauth2"
)

type Config struct {
	Host string

	Oauth2 oauth2.Config

	Key string

	PublicID int64

	UpdateFreq time.Duration
}

func Register(a *App, r yhttp.Registrar) {
	r.Pattern("GET", a.host, "/{$}", a.handleIndex, a.AuthN, a.AuthZ(auth.AllowAnonymous), httpencoding.Handler)
	r.Pattern("GET", a.host, "/auth/begin", a.authBegin, a.AuthN, a.AuthZ(auth.AllowRegistered))
	r.Pattern("GET", a.host, "/auth/callback", a.authCallback, a.AuthN, a.AuthZ(auth.AllowRegistered))
}

type App struct {
	o          yo11y.O11y
	mAdded     metric.Int64Counter
	mTracks    metric.Int64Gauge
	mPlaybacks metric.Int64Gauge

	// New
	http  *http.Client
	store *ystore.Store[*earbugv5.Store]

	// inserted
	AuthN yhttp.Interceptor
	AuthZ func(cel.Program) yhttp.Interceptor

	// config
	host       string
	bkt        *blob.Bucket
	dataKey    string
	oauth2     oauth2.Config
	publicID   int64
	updateFreq time.Duration
}

func New(c Config, bkt *blob.Bucket, o yo11y.O11y) (*App, error) {
	ctx := context.Background()

	a := &App{
		o: o.Sub("earbug"),
		http: &http.Client{
			Transport: otelhttp.NewTransport(http.DefaultTransport),
		},
		host:       c.Host,
		bkt:        bkt,
		dataKey:    c.Key,
		oauth2:     c.Oauth2,
		publicID:   c.PublicID,
		updateFreq: c.UpdateFreq,
	}

	a.mAdded, _ = a.o.M.Int64Counter("mono.earbug.playbacks.added", metric.WithUnit("track"))
	a.mPlaybacks, _ = a.o.M.Int64Gauge("mono.earbug.user.playbacks", metric.WithUnit("track"))
	a.mTracks, _ = a.o.M.Int64Gauge("mono.earbug.tracks", metric.WithUnit("track"))

	ctx, span := o.T.Start(ctx, "initData")
	defer span.End()

	store, err := ystore.New(ctx, bkt, c.Key, func() *earbugv5.Store {
		return earbugv5.Store_builder{
			Tracks: make(map[string]*earbugv5.Track),
			Users:  make(map[int64]*earbugv5.UserData),
		}.Build()
	})
	if err != nil {
		return nil, fmt.Errorf("init store: %w", err)
	}
	a.store = store

	// a.store.Do(ctx, a.migrate)
	// a.store.Sync(ctx)

	a.http = &http.Client{Transport: otelhttp.NewTransport(http.DefaultTransport)}
	return a, nil
}

// func (a *App) migrate(s *earbugv5.Store) {
// 	uid := int64(1167012155348904831)
// 	token := s.GetAuth().GetToken()
// 	playbacks := s.GetPlaybacks()
// 	data := &UserData{
// 		Token:     token,
// 		Playbacks: playbacks,
// 	}
//
// 	s.Playbacks = nil
// 	s.Auth = nil
// 	s.Users = make(map[int64]*earbugv5.UserData)
// 	s.Users[uid] = data
// }

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
