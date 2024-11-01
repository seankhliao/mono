package ulist

import (
	"context"
	"crypto/rand"
	"encoding/base32"
	"encoding/json"
	"net/http"

	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"golang.org/x/oauth2"
)

func (a *App) authBegin(rw http.ResponseWriter, r *http.Request) {
	_, span := a.o.T.Start(r.Context(), "authBegin")
	defer span.End()

	rawState := make([]byte, 32)
	rand.Read(rawState)
	state := base32.StdEncoding.EncodeToString(rawState)

	http.Redirect(rw, r, a.oauth2.AuthCodeURL(state), http.StatusTemporaryRedirect)
}

func (a *App) authCallback(rw http.ResponseWriter, r *http.Request) {
	ctx, span := a.o.T.Start(r.Context(), "authCallback")
	defer span.End()

	token, err := a.oauth2.Exchange(ctx, r.FormValue("code"))
	if err != nil {
		a.HTTPErr(ctx, "get token from request", err, rw, http.StatusBadRequest)
		return
	}

	httpClient := &http.Client{Transport: otelhttp.NewTransport(http.DefaultTransport)}
	ctx = context.WithValue(ctx, oauth2.HTTPClient, httpClient)
	// a.spo = spotify.New(a.oauth2.Client(ctx, token))

	tokenMarshaled, err := json.Marshal(token)
	if err != nil {
		a.HTTPErr(ctx, "marshal token", err, rw, http.StatusBadRequest)
		return
	}

	a.store.Do(func(s *Store) {
		s.Auth.Token = tokenMarshaled
	})

	rw.Write([]byte("success"))

	a.store.Sync(ctx)
}
