package ulist

import (
	"context"
	"fmt"
	"log/slog"
	"net/http"

	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/trace"
	"go.seankhliao.com/mono/yrun"
	"gocloud.dev/blob"
	"golang.org/x/oauth2"
)

type Config struct {
	Oauth oauth2.Config
}

type App struct {
	o yrun.O11y

	store *yrun.Store[*Store]

	oauth2 oauth2.Config
}

func New(c Config, bkt *blob.Bucket, o yrun.O11y) (*App, error) {
	ctx := context.Background()

	store, err := yrun.NewStore[Store](ctx, bkt, "ulist.pb.zstd", func() *Store {
		return &Store{}
	})
	if err != nil {
		return nil, fmt.Errorf("create store: %w", err)
	}

	return &App{
		store:  store,
		oauth2: c.Oauth,
	}, nil
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
