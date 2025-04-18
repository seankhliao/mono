package earbug

import (
	"context"
	"crypto/rand"
	"encoding/base32"
	"encoding/json/v2"
	"fmt"
	"net/http"

	"go.opentelemetry.io/otel/trace"
	earbugv5 "go.seankhliao.com/mono/earbug/v5"
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

	ctx = context.WithValue(ctx, oauth2.HTTPClient, a.http)

	// TODO: fix auth
	// info := auth.FromContext(ctx)
	//        userID := info.GetUserId()
	userID := int64(1167012155348904831)

	var tokenMarshaled []byte
	err := a.o.Region(ctx, "exchange", func(ctx context.Context, span trace.Span) error {
		token, err := a.oauth2.Exchange(ctx, r.FormValue("code"))
		if err != nil {
			return fmt.Errorf("token exchange: %w", err)
		}

		tokenMarshaled, err = json.Marshal(token)
		if err != nil {
			return fmt.Errorf("marshal token :%w", err)
		}
		return nil
	})
	if err != nil {
		a.o.HTTPErr(ctx, "exchange code for token", err, rw, http.StatusBadRequest)
		return
	}

	a.store.Do(ctx, func(s *earbugv5.Store) {
		data, ok := s.GetUsers()[userID]
		if !ok {
			data = &earbugv5.UserData{}
		}
		data.SetToken(tokenMarshaled)
		s.GetUsers()[userID] = data
	})

	rw.Write([]byte("success"))

	a.store.Sync(ctx, false)
}
