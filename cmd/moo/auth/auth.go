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
	"go.seankhliao.com/mono/yrun"
	"gocloud.dev/blob"
	"google.golang.org/protobuf/types/known/timestamppb"
)

func Register(a *App, r yrun.HTTPRegistrar) {
	r.Pattern("GET", a.host, "/{$}", http.HandlerFunc(a.homepage))
	r.Pattern("POST", a.host, "/login/start", a.requireAuth(http.HandlerFunc(a.loginStart), true))
	r.Pattern("POST", a.host, "/login/finish", a.requireAuth(http.HandlerFunc(a.loginFinish), true))
	r.Pattern("POST", a.host, "/register/start", a.requireAuth(http.HandlerFunc(a.registerStart), true))
	r.Pattern("POST", a.host, "/register/finish", a.requireAuth(http.HandlerFunc(a.registerFinish), true))
	r.Pattern("POST", a.host, "/update", a.RequireAuth(http.HandlerFunc(a.update)))
	r.Pattern("GET", a.host, "/logout", a.RequireAuth(http.HandlerFunc(a.logoutPage)))
	r.Pattern("POST", a.host, "/logout", a.RequireAuth(http.HandlerFunc(a.logoutAction)))
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

	store *yrun.Store[*Store]
}

func New(c Config, bkt *blob.Bucket, o yrun.O11y) (*App, error) {
	a := &App{
		host:         c.Host,
		cookieName:   c.CookieName,
		cookieDomain: c.CookieDomain,
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
	a.store, err = yrun.NewStore[*Store](ctx, bkt, "auth.pb.zstd")
	if err != nil {
		return nil, fmt.Errorf("init store: %w", err)
	}
	if a.store.Data.Sessions == nil {
		a.store.Data.Sessions = make(map[string]*TokenInfo)
	}
	if a.store.Data.Users == nil {
		a.store.Data.Users = make(map[int64]*UserInfo)
	}

	return a, nil
}

func (a *App) RequireAuth(next http.Handler) http.Handler {
	return a.requireAuth(next, false)
}

func (a *App) requireAuth(next http.Handler, allowAnonymous bool) http.Handler {
	return http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
		ctx := r.Context()

		info, ok := a.requestUser(r)
		if !ok {
			http.Redirect(rw, r, "/", http.StatusFound)
			return
		}
		if info.GetUserID() <= 0 && !allowAnonymous {
			http.Redirect(rw, r, "/", http.StatusFound)
			return
		}

		ctx = context.WithValue(ctx, TokenInfoContextKey, info)
		r = r.WithContext(ctx)

		next.ServeHTTP(rw, r)
	})
}

// Debug handlers

func (a *App) adminToken(rw http.ResponseWriter, r *http.Request) {
	rawToken := make([]byte, 16)
	rand.Read(rawToken)
	token := []byte("mooa_")
	token = base32.StdEncoding.AppendEncode(token, rawToken)

	tokenInfo := TokenInfo{
		SessionID: ptr(string(token)),
		Created:   timestamppb.Now(),
		UserID:    ptr[int64](-1),
	}

	a.store.Lock()
	a.store.Data.Sessions[*tokenInfo.SessionID] = &tokenInfo
	a.store.Unlock()

	rw.Write(token)
}

func ptr[T any](v T) *T {
	return &v
}
