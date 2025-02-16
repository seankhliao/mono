package goproxyaudit

import (
	"context"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"time"

	"github.com/cockroachdb/pebble"
	"github.com/go-json-experiment/json"
	"github.com/go-json-experiment/json/jsontext"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	goproxyauditv1 "go.seankhliao.com/mono/goproxyaudit/v1"
	"go.seankhliao.com/mono/yhttp"
	"go.seankhliao.com/mono/ykv"
	"go.seankhliao.com/mono/yo11y"
	"google.golang.org/protobuf/types/known/timestamppb"
)

func Register(a *App, r yhttp.Registrar) {
}

func Background(a *App) []func(context.Context) error {
	return []func(context.Context) error{
		a.watchIndex,
	}
}

func Shutdown(a *App) []func(context.Context) error {
	return []func(context.Context) error{
		a.kv.Shutdown,
	}
}

type Config struct {
	Host string
}

type App struct {
	http *http.Client
	o    yo11y.O11y

	// progress/since
	// module/<module>/version/<version>/info
	kv *ykv.KV
}

func New(ctx context.Context, c Config, o yo11y.O11y) (*App, error) {
	var a App

	a.http = &http.Client{
		Transport: &yhttp.UserAgent{
			Next: otelhttp.NewTransport(http.DefaultTransport),
		},
	}

	a.o = o.Sub("goproxyaudit")

	var err error
	a.kv, err = ykv.New(ctx, "/data/db.pebble")
	if err != nil {
		return nil, fmt.Errorf("init store: %w", err)
	}

	return &a, nil
}

const indexURL = "https://index.golang.org/index?since="

func (a *App) watchIndex(ctx context.Context) error {
	for {
		since, err := a.updateFromIndex(ctx)
		if err != nil {
			sleep := time.Minute
			a.o.Err(ctx, "error updating from index.golang.org", err,
				slog.Time("since", since),
				slog.Duration("retry.after", sleep),
			)
			time.Sleep(sleep)
			continue
		}

		sinceLastSeen := time.Since(since)
		sleep := 5*time.Minute - sinceLastSeen
		if sleep < 0 {
			continue
		}
		a.o.L.LogAttrs(ctx, slog.LevelDebug, "sleeping",
			slog.Duration("duration", sleep),
		)
		time.Sleep(sleep)
	}
}

func (a *App) updateFromIndex(ctx context.Context) (time.Time, error) {
	ctx, span := a.o.T.Start(ctx, "updateFromIndex")
	defer span.End()

	// last processed time
	kvTimestamp := ykv.View[timestamppb.Timestamp](a.kv)
	sinceTS, err := kvTimestamp.Get("progress/since")
	if err != nil {
		return time.Time{}, fmt.Errorf("read last")
	}
	since := sinceTS.AsTime()

	// fetch
	uri := indexURL + since.Format(time.RFC3339)
	req, err := http.NewRequestWithContext(ctx, "GET", uri, http.NoBody)
	if err != nil {
		return since, fmt.Errorf("prepare request: %w", err)
	}
	res, err := a.http.Do(req)
	if err != nil {
		return since, fmt.Errorf("get from index: %w", err)
	}
	defer res.Body.Close()

	// process each record
	kvMod := ykv.View[goproxyauditv1.ModuleVersion](a.kv)
	jtdec := jsontext.NewDecoder(res.Body)
	var processed int
	for {
		var rec IndexRecord
		err = json.UnmarshalDecode(jtdec, &rec)
		if errors.Is(err, io.EOF) {
			break
		} else if err != nil {
			return since, a.o.Err(ctx, "decode record", err,
				slog.String("module", rec.Path),
			)
		}

		processed++

		key := fmt.Sprintf("module/%s/version/%s/info", rec.Path, rec.Version)
		mod, err := kvMod.Get(key)
		if errors.Is(err, pebble.ErrNotFound) {
			mod = goproxyauditv1.ModuleVersion_builder{
				Version:          &rec.Version,
				GolangOrgIndexed: timestamppb.New(rec.Timestamp),
			}.Build()
		} else if err != nil {
			return since, a.o.Err(ctx, "get module from kv store", err,
				slog.String("key", key),
			)
		}

		err = kvMod.Set(key, mod)
		if err != nil {
			return since, a.o.Err(ctx, "store module to kv store", err,
				slog.String("key", key),
			)
		}

		since = rec.Timestamp
	}

	kvTimestamp.Set("progress/since", timestamppb.New(since))
	a.o.L.LogAttrs(ctx, slog.LevelInfo, "updated from index.golang.org",
		slog.Int("processed", processed),
		slog.Time("last", since),
	)

	return since, nil
}

type IndexRecord struct {
	Path      string
	Version   string
	Timestamp time.Time
}
