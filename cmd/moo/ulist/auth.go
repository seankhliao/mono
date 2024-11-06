package ulist

import (
	"crypto/rand"
	"encoding/base32"
	"encoding/json"
	"net/http"

	"go.seankhliao.com/mono/cmd/moo/auth"
	"go.seankhliao.com/mono/cmd/moo/ulist/ulistv1"
	"golang.org/x/oauth2"
)

func (a *App) authBegin(rw http.ResponseWriter, r *http.Request) {
	_, span := a.o.T.Start(r.Context(), "authBegin")
	defer span.End()

	rawState := make([]byte, 32)
	rand.Read(rawState)
	state := base32.StdEncoding.EncodeToString(rawState)

	u := a.oauth2.AuthCodeURL(state, oauth2.AccessTypeOffline, oauth2.ApprovalForce)
	http.Redirect(rw, r, u, http.StatusTemporaryRedirect)
}

func (a *App) authCallback(rw http.ResponseWriter, r *http.Request) {
	ctx, span := a.o.T.Start(r.Context(), "authCallback")
	defer span.End()

	info := auth.FromContext(ctx)

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

	a.store.Do(func(s *ulistv1.Store) {
		data, ok := s.Users[info.GetUserId()]
		if !ok {
			data = &ulistv1.UserData{}
		}
		data.Token = tokenMarshaled
		s.Users[info.GetUserId()] = data
	})

	rw.Write([]byte("success"))

	a.store.Sync(ctx)
}
