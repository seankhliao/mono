package auth

import (
	"context"
	"crypto/rand"
	_ "embed"
	"encoding/base32"
	"fmt"
	"net/http"

	"github.com/go-webauthn/webauthn/protocol"
	"github.com/go-webauthn/webauthn/webauthn"
	"go.seankhliao.com/mono/cmd/moo/auth/authv1"
	"go.seankhliao.com/mono/httpencoding"
	"go.seankhliao.com/mono/yrun"
	"gocloud.dev/blob"
	"google.golang.org/protobuf/types/known/timestamppb"
)

func Register(a *App, r yrun.HTTPRegistrar) {
	// web
	r.Pattern("GET", a.host, "/{$}", a.homepage, a.AuthN, a.AuthZ(AllowAnonymous), httpencoding.Handler)
	r.Pattern("GET", a.host, "/logout", a.logoutPage, a.AuthN, a.AuthZ(AllowRegistered), httpencoding.Handler)
	// api
	r.Pattern("POST", a.host, "/login/start", a.loginStart, a.AuthN, a.AuthZ(AllowAnonymous))
	r.Pattern("POST", a.host, "/login/finish", a.loginFinish, a.AuthN, a.AuthZ(AllowAnonymous))
	r.Pattern("POST", a.host, "/register/start", a.registerStart, a.AuthN, a.AuthZ(AllowAnonymous))
	r.Pattern("POST", a.host, "/register/finish", a.registerFinish, a.AuthN, a.AuthZ(AllowAnonymous))
	r.Pattern("POST", a.host, "/update", a.update, a.AuthN, a.AuthZ(AllowRegistered))
	r.Pattern("POST", a.host, "/logout", a.logoutAction, a.AuthN, a.AuthZ(AllowRegistered))
}

func Admin(a *App, r yrun.HTTPRegistrar) {
	r.Pattern("GET", "", "/auth/admin-token", http.HandlerFunc(a.adminToken))
}

// Config from a config file
type Config struct {
	Host         string
	CookieDomain string
	CookieName   string
}

type App struct {
	host         string
	cookieName   string
	cookieDomain string

	webauthn *webauthn.WebAuthn

	o     yrun.O11y
	store *yrun.Store[*authv1.Store]
}

func New(c Config, bkt *blob.Bucket, o yrun.O11y) (*App, error) {
	a := &App{
		host:         c.Host,
		cookieName:   c.CookieName,
		cookieDomain: c.CookieDomain,
		o:            o.Sub("auth"),
	}

	var err error
	t := true
	a.webauthn, err = webauthn.New(&webauthn.Config{
		RPID:          c.Host,
		RPDisplayName: c.Host,
		RPOrigins: []string{
			"https://" + c.Host,
		},
		AuthenticatorSelection: protocol.AuthenticatorSelection{
			RequireResidentKey: &t,
			ResidentKey:        protocol.ResidentKeyRequirementRequired,
		},
	})
	if err != nil {
		return nil, err
	}

	ctx := context.Background()
	a.store, err = yrun.NewStore(ctx, bkt, "auth.pb.zstd", func() *authv1.Store {
		return &authv1.Store{
			Users:    make(map[int64]*authv1.UserInfo),
			Sessions: make(map[string]*authv1.TokenInfo),
		}
	})
	if err != nil {
		return nil, fmt.Errorf("init store: %w", err)
	}

	// a.store.Do(a.migrate)
	// a.store.Sync(ctx)

	return a, nil
}

// func (a *App) migrate(s *authv1.Store) {
// 	for id, user := range s.Users {
// 		if len(user.Credentials) == 0 {
// 			continue
// 		}
// 		for _, cred := range user.Credentials {
// 			user.Creds = append(user.Creds, &Credential{
// 				Name: ptr("google"),
// 				Cred: cred,
// 			})
// 		}
// 		s.Users[id] = user
// 	}
// }

// Debug handlers

func (a *App) adminToken(rw http.ResponseWriter, r *http.Request) {
	rawToken := make([]byte, 16)
	rand.Read(rawToken)
	token := []byte("mooa_")
	token = base32.StdEncoding.AppendEncode(token, rawToken)

	tokenInfo := &authv1.TokenInfo{
		SessionId: ptr(string(token)),
		Created:   timestamppb.Now(),
		UserId:    ptr[int64](-1),
	}

	a.store.Do(func(s *authv1.Store) {
		s.Sessions[tokenInfo.GetSessionId()] = tokenInfo
	})

	rw.Write(token)
}

func ptr[T any](v T) *T {
	return &v
}
