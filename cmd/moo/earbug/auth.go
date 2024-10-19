package earbug

import (
	"context"
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"errors"
	"net/http"

	"github.com/zmb3/spotify/v2"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.seankhliao.com/mono/cmd/moo/earbug/earbugv4"
	"golang.org/x/oauth2"
	oauthspotify "golang.org/x/oauth2/spotify"
)

func (a *App) hAuthorize(rw http.ResponseWriter, r *http.Request) {
	ctx, span := a.o.T.Start(r.Context(), "Authorize")
	defer span.End()

	clientID, clientSecret := func() (clientID, clientSecret string) {
		a.store.Lock()
		defer a.store.Unlock()
		clientID = r.FormValue("client_id")
		if clientID == "" && (a.store.Data.Auth != nil && a.store.Data.Auth.ClientId != "") {
			clientID = a.store.Data.Auth.ClientId
		} else {
			if a.store.Data.Auth == nil {
				a.store.Data.Auth = &earbugv4.Auth{}
			}
			a.store.Data.Auth.ClientId = clientID
		}
		clientSecret = r.FormValue("client_secret")
		if clientSecret == "" && (a.store.Data.Auth != nil && a.store.Data.Auth.ClientSecret != "") {
			clientSecret = a.store.Data.Auth.ClientSecret
		} else {
			a.store.Data.Auth.ClientSecret = clientSecret
		}
		return
	}()
	if clientID == "" || clientSecret == "" {
		a.HTTPErr(ctx, "no client id/secret", errors.New("missing oauth client"), rw, http.StatusBadRequest)
		return
	}

	as := NewAuthState(clientID, clientSecret, a.authURL)
	a.authState.Store(as)

	http.Redirect(rw, r, as.conf.AuthCodeURL(as.state), http.StatusTemporaryRedirect)

	a.store.Sync(ctx)
}

func (a *App) hAuthCallback(rw http.ResponseWriter, r *http.Request) {
	ctx, span := a.o.T.Start(r.Context(), "hAuthCallback")
	defer span.End()

	as := a.authState.Load()
	token, err := as.conf.Exchange(ctx, r.FormValue("code"))
	if err != nil {
		a.HTTPErr(ctx, "get token from request", err, rw, http.StatusBadRequest)
		return
	}

	httpClient := &http.Client{Transport: otelhttp.NewTransport(http.DefaultTransport)}
	ctx = context.WithValue(ctx, oauth2.HTTPClient, httpClient)
	httpClient = as.conf.Client(ctx, token)
	spotClient := spotify.New(httpClient)

	tokenMarshaled, err := json.Marshal(token)
	if err != nil {
		a.HTTPErr(ctx, "marshal token", err, rw, http.StatusBadRequest)
		return
	}

	func() {
		a.store.Lock()
		defer a.store.Unlock()
		a.store.Data.Auth.Token = tokenMarshaled
		a.spot = spotClient
	}()

	rw.Write([]byte("success"))

	a.store.Sync(ctx)
}

type AuthState struct {
	state string
	conf  *oauth2.Config
}

func NewAuthState(clientID, clientSecret, redirectURL string) *AuthState {
	buf := make([]byte, 256)
	rand.Read(buf)
	return &AuthState{
		state: base64.StdEncoding.EncodeToString(buf),
		conf: &oauth2.Config{
			ClientID:     clientID,
			ClientSecret: clientSecret,
			Endpoint: oauth2.Endpoint{
				AuthURL:   oauthspotify.Endpoint.AuthURL,
				TokenURL:  oauthspotify.Endpoint.TokenURL,
				AuthStyle: oauth2.AuthStyleInHeader,
			},
			RedirectURL: redirectURL,
			Scopes:      []string{"user-read-recently-played"},
		},
	}
}
