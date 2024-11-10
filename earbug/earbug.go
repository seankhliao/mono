package earbug

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/google/cel-go/cel"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.seankhliao.com/mono/auth"
	earbugv5 "go.seankhliao.com/mono/earbug/v5"
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

	PublicID int64

	UpdateFreq time.Duration
}

func Register(a *App, r yrun.HTTPRegistrar) {
	r.Pattern("GET", a.host, "/{$}", a.handleIndex, a.AuthN, a.AuthZ(auth.AllowAnonymous), httpencoding.Handler)
	r.Pattern("GET", a.host, "/auth/begin", a.authBegin, a.AuthN, a.AuthZ(auth.AllowRegistered))
	r.Pattern("GET", a.host, "/auth/callback", a.authCallback, a.AuthN, a.AuthZ(auth.AllowRegistered))
}

type App struct {
	o yrun.O11y

	// New
	http  *http.Client
	store *yrun.Store[*earbugv5.Store]

	// inserted
	AuthN yrun.HTTPInterceptor
	AuthZ func(cel.Program) yrun.HTTPInterceptor

	// config
	host       string
	bkt        *blob.Bucket
	dataKey    string
	oauth2     oauth2.Config
	publicID   int64
	updateFreq time.Duration
}

func New(c Config, bkt *blob.Bucket, o yrun.O11y) (*App, error) {
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

	ctx, span := o.T.Start(ctx, "initData")
	defer span.End()

	store, err := yrun.NewStore(ctx, bkt, c.Key, func() *earbugv5.Store {
		return &earbugv5.Store{
			Tracks: make(map[string]*earbugv5.Track),
			Users:  make(map[int64]*earbugv5.UserData),
		}
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
