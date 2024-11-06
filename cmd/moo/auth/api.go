package auth

import (
	"context"
	"crypto/rand"
	"encoding/base32"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"time"

	"github.com/google/cel-go/cel"
	"go.seankhliao.com/mono/cmd/moo/auth/authv1"
	"google.golang.org/protobuf/types/known/timestamppb"
)

// SessionID is also the cookie Value
// has a prefix of:
//   - moou_ for user tokens
//   - moox_ for anonymous tokens
//   - mooa_ for admin tokens

// UserId is identifies the user
//   - > 0 for valid users
//   - = 0 for anonymous users
//   - < 0 for admin tokens

type tokenInfoContextKey struct{}

var TokenInfoContextKey = tokenInfoContextKey{}

func FromContext(ctx context.Context) *authv1.TokenInfo {
	val := ctx.Value(TokenInfoContextKey)
	info, ok := val.(*authv1.TokenInfo)
	if !ok {
		return nil
	}
	return info
}

// AuthN ensures there's always a valid session.
// The user may be anonymous (UserId == 0).
func (a *App) AuthN(next http.Handler) http.Handler {
	return http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
		ctx, span := a.o.T.Start(r.Context(), "authn")
		defer span.End()

		// get current session token
		var info *authv1.TokenInfo
		cookie, err := r.Cookie(a.cookieName)
		if err == nil {
			a.store.RDo(func(s *authv1.Store) {
				info = s.Sessions[cookie.Value]
			})
			// TODO: check for session expiry?
		}
		if info == nil {
			// start a new anonymous session
			rawToken := make([]byte, 16)
			rand.Read(rawToken)
			token := []byte("moox_")
			token = base32.StdEncoding.AppendEncode(token, rawToken)
			info = &authv1.TokenInfo{
				SessionId: ptr(string(token)),
				Created:   timestamppb.Now(),
			}

			a.store.Do(func(s *authv1.Store) {
				s.Sessions[info.GetSessionId()] = info
			})

			// send it to the client
			http.SetCookie(rw, &http.Cookie{
				Name:        a.cookieName,
				Value:       info.GetSessionId(),
				Path:        "/",
				Domain:      a.cookieDomain,
				MaxAge:      int(time.Hour.Seconds()),
				Secure:      true,
				HttpOnly:    true,
				SameSite:    http.SameSiteStrictMode,
				Partitioned: true,
			})
		}

		ctx = context.WithValue(ctx, TokenInfoContextKey, info)
		r = r.WithContext(ctx)
		next.ServeHTTP(rw, r)
	})
}

var (
	AllowAnonymous  = MustAuthZPolicy(`user_id >= 0`)
	AllowRegistered = MustAuthZPolicy(`user_id > 0`)
)

func MustAuthZPolicy(policy string) cel.Program {
	prog, err := AuthZPolicy(policy)
	if err != nil {
		panic(err)
	}
	return prog
}

func AuthZPolicy(policy string) (cel.Program, error) {
	var info *authv1.TokenInfo
	env, err := cel.NewEnv(
		cel.DeclareContextProto(info.ProtoReflect().Descriptor()),
	)
	if err != nil {
		return nil, fmt.Errorf("prepare policy env: %w", err)
	}
	ast, iss := env.Compile(policy)
	if iss.Err() != nil {
		return nil, fmt.Errorf("compile policy: %w", err)
	}
	prog, err := env.Program(ast)
	if err != nil {
		return nil, fmt.Errorf("prepare policy program: %w", err)
	}
	return prog, nil
}

func (a *App) AuthZ(next http.Handler, policy cel.Program) http.Handler {
	return http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
		ctx, span := a.o.T.Start(r.Context(), "authz")
		defer span.End()

		info := FromContext(ctx)
		act, err := cel.ContextProtoVars(info)
		if err != nil {
			http.Error(rw, err.Error(), http.StatusInternalServerError)
			return
		}
		res, _, err := policy.ContextEval(ctx, act)
		if err != nil {
			http.Error(rw, err.Error(), http.StatusInternalServerError)
			return
		}
		allow, ok := res.Value().(bool)
		if !ok {
			err = errors.New("policy didn't eval to bool")
			http.Error(rw, err.Error(), http.StatusInternalServerError)
			return
		}
		if !allow {
			q := make(url.Values)
			if r.Host != a.host {
				q.Set("return", (&url.URL{
					Scheme:   "https",
					Host:     r.Host,
					Path:     r.URL.Path,
					RawQuery: r.URL.RawQuery,
				}).String())
			}

			u := (&url.URL{
				Scheme:   "https",
				Host:     a.host,
				Path:     "/",
				RawQuery: q.Encode(),
			}).String()
			http.Redirect(rw, r, u, http.StatusTemporaryRedirect)
			return
		}

		next.ServeHTTP(rw, r)
	})
}
