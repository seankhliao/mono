package earbug

import (
	"crypto/rand"
	"encoding/base32"
	"encoding/json"
	"net/http"

	"go.seankhliao.com/mono/cmd/moo/auth"
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

	userInfo := ctx.Value(auth.TokenInfoContextKey).(*auth.TokenInfo)

	token, err := a.oauth2.Exchange(ctx, r.FormValue("code"))
	if err != nil {
		a.HTTPErr(ctx, "get token from request", err, rw, http.StatusBadRequest)
		return
	}

	tokenMarshaled, err := json.Marshal(token)
	if err != nil {
		a.HTTPErr(ctx, "marshal token", err, rw, http.StatusBadRequest)
		return
	}

	a.store.Do(func(s *Store) {
		data, ok := s.Users[userInfo.GetUserID()]
		if !ok {
			data = &UserData{}
		}
		data.Token = tokenMarshaled
		s.Users[userInfo.GetUserID()] = data
	})

	rw.Write([]byte("success"))

	a.store.Sync(ctx)
}
