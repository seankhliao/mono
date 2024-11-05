package ulist

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"net/http"

	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/trace"
	"go.seankhliao.com/mono/cmd/moo/auth"
	"go.seankhliao.com/mono/yrun"
	"gocloud.dev/blob"
	"golang.org/x/oauth2"
	"google.golang.org/api/youtube/v3"
)

func Register(a *App, r yrun.HTTPRegistrar) {
	r.Pattern("GET", a.host, "/test", a.Auth(http.HandlerFunc(a.test)))
	r.Pattern("GET", a.host, "/auth/begin", a.Auth(http.HandlerFunc(a.authBegin)))
	r.Pattern("GET", a.host, "/auth/callback", a.Auth(http.HandlerFunc(a.authCallback)))
}

type Config struct {
	Host   string
	Oauth2 oauth2.Config
}

type App struct {
	host string
	o    yrun.O11y

	Auth func(http.Handler) http.Handler

	store  *yrun.Store[*Store]
	oauth2 oauth2.Config
	http   *http.Client
}

func New(c Config, bkt *blob.Bucket, o yrun.O11y) (*App, error) {
	ctx := context.Background()

	store, err := yrun.NewStore(ctx, bkt, "ulist.pb.zstd", func() *Store {
		return &Store{
			Users: make(map[int64]*UserData),
		}
	})
	if err != nil {
		return nil, fmt.Errorf("create store: %w", err)
	}

	return &App{
		host:   c.Host,
		o:      o.Sub("ulist"),
		store:  store,
		oauth2: c.Oauth2,
		http:   &http.Client{Transport: otelhttp.NewTransport(http.DefaultTransport)},
	}, nil
}

func (a *App) test(rw http.ResponseWriter, r *http.Request) {
	ctx, span := a.o.T.Start(r.Context(), "test")
	defer span.End()

	info := ctx.Value(auth.TokenInfoContextKey).(*auth.TokenInfo)

	var rawToken []byte
	a.store.RDo(func(s *Store) {
		data := s.Users[info.GetUserID()]
		rawToken = data.GetToken()
	})
	var token oauth2.Token
	err := json.Unmarshal(rawToken, &token)
	if err != nil {
		a.HTTPErr(ctx, "parse stored token", err, rw, http.StatusInternalServerError)
		return
	}

	ctx = context.WithValue(ctx, oauth2.HTTPClient, a.http)
	oclient := a.oauth2.Client(ctx, &token)
	client, err := youtube.New(oclient)
	if err != nil {
		a.HTTPErr(ctx, "create client", err, rw, http.StatusInternalServerError)
		return
	}

	err = client.Playlists.List([]string{"snippet", "contentDetails"}).Mine(true).Pages(ctx, func(plr *youtube.PlaylistListResponse) error {
		for _, item := range plr.Items {
			fmt.Fprintln(rw, item.Snippet.Title, item.ContentDetails.ItemCount)
		}
		return nil
	})
	if err != nil {
		a.HTTPErr(ctx, "page over playlists", err, rw, http.StatusInternalServerError)
		return
	}
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
