package serve

import (
	"context"
	"errors"
	"fmt"
	"net"
	"net/http"
	"net/url"
	"time"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/trace"
	"go.seankhliao.com/mono/spanerr"
)

func RunBackgroundTimers(ctx context.Context, c Config) error {
	tr := otel.Tracer("backgoundtimer")

	host, port, err := net.SplitHostPort(c.HTTP.Addr)
	if err != nil {
		return fmt.Errorf("parse http addr: %w", err)
	}
	if host == "" {
		host = "127.0.0.1"
	}

	go func() {
		func() {
			ctx, span := tr.Start(ctx, "wait for server liveness")
			defer span.End()

			liveness := &url.URL{Scheme: "http", Host: net.JoinHostPort(host, port), Path: "/debug/liveness"}
			req, _ := http.NewRequestWithContext(ctx, http.MethodGet, liveness.String(), http.NoBody)

			for i, backoff := 1, 100*time.Millisecond; ; i++ {
				attrs := []attribute.KeyValue{attribute.Int("attempt", i)}
				ok := runBackgroundRequest(ctx, tr, attrs, req)
				if ok {
					break
				}
				backoff = max(2*time.Second, 5*time.Second)
				time.Sleep(backoff)
			}
		}()

		tasks := []BackgroundTask{
			// TODO
		}
		for _, task := range tasks {
			go runBackgroundTask(ctx, tr, net.JoinHostPort(host, port), task)
		}
	}()
	return nil
}

type BackgroundTask struct {
	Name      string
	Frequency time.Duration
	Path      string
}

func runBackgroundTask(ctx context.Context, tr trace.Tracer, host string, task BackgroundTask) {
	endpoint := &url.URL{Scheme: "http", Host: host, Path: task.Path}

	attrs := []attribute.KeyValue{
		attribute.String("task", task.Name),
		attribute.String("frequency", task.Frequency.String()),
		attribute.String("endpoint", endpoint.String()),
	}

	req, _ := http.NewRequestWithContext(ctx, http.MethodGet, endpoint.String(), http.NoBody)

	runBackgroundRequest(ctx, tr, attrs, req)
	tick := time.NewTicker(task.Frequency)
	defer tick.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-tick.C:
			runBackgroundRequest(ctx, tr, attrs, req)
		}
	}
}

func runBackgroundRequest(ctx context.Context, tr trace.Tracer, attrs []attribute.KeyValue, req *http.Request) (ok bool) {
	ctx, span := tr.Start(ctx, "run background task", trace.WithAttributes(attrs...))
	defer span.End()

	res, err := http.DefaultClient.Do(req.Clone(ctx))
	if err != nil {
		spanerr.Err(span, "do background task", err)
		return false
	}
	if res.StatusCode < 200 || res.StatusCode > 299 {
		spanerr.Err(span, "non-success status code", errors.New(res.Status),
			attribute.Int("response.status", res.StatusCode))
		return false
	}
	return true
}
