package authed

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"time"

	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.seankhliao.com/mono/observability"
)

const cookieName = "authsvr_session"

var SessionInfoKey = sessionInfoKey{}

type sessionInfoKey struct{}

type SessionInfo struct {
	UserID    int64
	Email     string
	StartTime time.Time
	UserAgent string
}

type Authed struct {
	Endpoint string
	Client   *http.Client
	o        *observability.O
}

func New(o *observability.O) *Authed {
	return &Authed{
		Endpoint: "http://authsvr.authsvr.svc",
		Client: &http.Client{
			Transport: otelhttp.NewTransport(http.DefaultTransport),
		},
		o: o,
	}
}

func (a *Authed) Authed(h http.Handler) http.Handler {
	return http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
		ctx, span := a.o.T.Start(r.Context(), "authed handler")
		defer span.End()

		requested := url.URL{Scheme: "https", Host: r.Host, Path: r.URL.Path, RawQuery: r.URL.RawQuery}
		u := "https://auth.liao.dev/?" + url.Values{"redirect": []string{requested.String()}}.Encode()

		c, err := r.Cookie(cookieName)
		if err != nil {
			http.Redirect(rw, r, u, http.StatusFound)
			return
		}

		info, err := a.check(ctx, c)
		if err != nil {
			http.Redirect(rw, r, u, http.StatusFound)
			return
		}

		ctx = context.WithValue(ctx, SessionInfoKey, info)
		r = r.WithContext(ctx)
		h.ServeHTTP(rw, r)
	})
}

func (a *Authed) check(ctx context.Context, c *http.Cookie) (SessionInfo, error) {
	u := a.Endpoint + "/api/v1/token/" + c.Value
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, u, http.NoBody)
	if err != nil {
		return SessionInfo{}, fmt.Errorf("create check http request: %w", err)
	}
	res, err := a.Client.Do(req)
	if err != nil {
		return SessionInfo{}, fmt.Errorf("do check http request: %w", err)
	} else if res.StatusCode != 200 {
		return SessionInfo{}, fmt.Errorf("check http request unsuccessful: %v", res.Status)
	}
	defer res.Body.Close()
	b, err := io.ReadAll(res.Body)
	if err != nil {
		return SessionInfo{}, fmt.Errorf("read check response: %w", err)
	}
	var info SessionInfo
	err = json.Unmarshal(b, &info)
	if err != nil {
		return SessionInfo{}, fmt.Errorf("parse check response: %w", err)
	}

	return info, nil
}
