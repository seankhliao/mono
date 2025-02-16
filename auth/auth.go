package auth

import (
	"context"
	"crypto/rand"
	_ "embed"
	"encoding/base32"
	"net/http"

	"github.com/go-webauthn/webauthn/protocol"
	"github.com/go-webauthn/webauthn/webauthn"
	"go.opentelemetry.io/otel/metric"
	authv1 "go.seankhliao.com/mono/auth/v1"
	"go.seankhliao.com/mono/httpencoding"
	"go.seankhliao.com/mono/yhttp"
	"go.seankhliao.com/mono/yo11y"
	"go.seankhliao.com/mono/ystore"
	"google.golang.org/protobuf/types/known/timestamppb"
)

func Register(a *App, r yhttp.Registrar) {
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

func Admin(a *App, r yhttp.Registrar) {
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

	o         yo11y.O11y
	mLogins   metric.Int64Counter
	mSessions metric.Int64Gauge
	mAuthz    metric.Int64Counter

	store *ystore.Store[*authv1.Store]
}

func New(ctx context.Context, c Config, o yo11y.O11y) (*App, error) {
	a := &App{
		host:         c.Host,
		cookieName:   c.CookieName,
		cookieDomain: c.CookieDomain,
		o:            o.Sub("auth"),
	}

	a.mLogins, _ = a.o.M.Int64Counter("mono.auth.logins", metric.WithUnit("login"))
	a.mSessions, _ = a.o.M.Int64Gauge("mono.auth.sessions", metric.WithUnit("session"))
	a.mAuthz, _ = a.o.M.Int64Counter("mono.auth.authz.checks", metric.WithUnit("check"))

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

	// a.store, err = ystore.New(ctx, bkt, "auth.pb.zstd", func() *authv1.Store {
	// 	return authv1.Store_builder{
	// 		Users:    make(map[int64]*authv1.UserInfo),
	// 		Sessions: make(map[string]*authv1.TokenInfo),
	// 	}.Build()
	// })
	// if err != nil {
	// 	return nil, fmt.Errorf("init store: %w", err)
	// }
	// a.store.Do(ctx, func(s *authv1.Store) {
	// 	if s.GetSessions() == nil {
	// 		s.SetSessions(make(map[string]*authv1.TokenInfo))
	// 	}
	// 	if s.GetUsers() == nil {
	// 		s.SetUsers(make(map[int64]*authv1.UserInfo))
	// 	}
	// })

	// a.store.Do(ctx, a.migrate)
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
	ctx, span := a.o.T.Start(r.Context(), "generate admin token")
	defer span.End()

	token := genToken("mooa_")
	tokenInfo := authv1.TokenInfo_builder{
		SessionId: &token,
		Created:   timestamppb.Now(),
		UserId:    ptr[int64](-1),
	}.Build()

	a.store.Do(ctx, func(s *authv1.Store) {
		s.GetSessions()[tokenInfo.GetSessionId()] = tokenInfo
	})

	rw.Write([]byte(token))
}

func genToken(prefix string) string {
	raw := make([]byte, 32)
	rand.Read(raw)
	return prefix + base32.StdEncoding.WithPadding(base32.NoPadding).EncodeToString(raw)
}

func ptr[T any](v T) *T {
	return &v
}
