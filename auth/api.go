package auth

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"time"

	"github.com/google/cel-go/cel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/trace"
	authv1 "go.seankhliao.com/mono/auth/v1"
	"go.seankhliao.com/mono/yrun"
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

var (
	_ yrun.HTTPInterceptor = (&App{}).AuthN
	_ yrun.HTTPInterceptor = (&App{}).AuthZ(AllowAnonymous)
)

// AuthN ensures there's always a valid session.
// The user may be anonymous (UserId == 0).
func (a *App) AuthN(next http.Handler) http.Handler {
	return http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
		var info *authv1.TokenInfo
		a.o.Region(r.Context(), "authentication", func(ctx context.Context, span trace.Span) error {
			// get current session token
			cookie, err := r.Cookie(a.cookieName)
			if err == nil {
				a.store.RDo(ctx, func(s *authv1.Store) {
					info = s.Sessions[cookie.Value]
				})
				// TODO: check for session expiry?
			}
			if info == nil {
				span.SetAttributes(
					attribute.Bool("session.new", true),
				)
				// start a new anonymous session
				token := genToken("moox_")
				info = &authv1.TokenInfo{
					SessionId: &token,
					Created:   timestamppb.Now(),
				}

				a.store.Do(ctx, func(s *authv1.Store) {
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

			span.SetAttributes(
				attribute.Int64("user.id", info.GetUserId()),
				attribute.String("session.id", info.GetSessionId()),
				attribute.Float64("session.age.seconds", time.Since(info.GetCreated().AsTime()).Seconds()),
			)
			return nil
		})

		ctx := context.WithValue(r.Context(), TokenInfoContextKey, info)
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

var errUnauthorized = errors.New("unauthorized")

func (a *App) AuthZ(policy cel.Program) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
			err := a.o.Region(r.Context(), "authorization", func(ctx context.Context, span trace.Span) error {
				info := FromContext(ctx)
				act, err := cel.ContextProtoVars(info)
				if err != nil {
					return fmt.Errorf("prepare authz eval context: %w", err)
				}
				res, _, err := policy.ContextEval(ctx, act)
				if err != nil {
					return fmt.Errorf("evaluate policy: %w", err)
				}
				allow, ok := res.Value().(bool)
				if !ok {
					return fmt.Errorf("policy eval result type %T", res.Value())
				}
				span.SetAttributes(
					attribute.Bool("auth.allow", allow),
				)
				if !allow {
					return errUnauthorized
				}
				return nil
			})
			if errors.Is(err, errUnauthorized) {
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
			} else if err != nil {
				http.Error(rw, err.Error(), http.StatusInternalServerError)
				return
			}

			next.ServeHTTP(rw, r)
		})
	}
}
