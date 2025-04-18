package auth

import (
	"context"
	_ "embed"
	"encoding/json/v2"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"time"

	"github.com/go-webauthn/webauthn/protocol"
	"github.com/go-webauthn/webauthn/webauthn"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/metric"
	"go.opentelemetry.io/otel/trace"
	authv1 "go.seankhliao.com/mono/auth/v1"
	"google.golang.org/protobuf/types/known/timestamppb"
)

func (a *App) loginStart(rw http.ResponseWriter, r *http.Request) {
	ctx, span := a.o.T.Start(r.Context(), "loginStart")
	defer span.End()
	cred, err := func() (*protocol.CredentialAssertion, error) {
		info := FromContext(ctx)

		cred, sess, err := a.webauthn.BeginDiscoverableLogin(
			webauthn.WithAssertionPublicKeyCredentialHints([]protocol.PublicKeyCredentialHints{
				protocol.PublicKeyCredentialHintHybrid,
			}),
		)
		if err != nil {
			return nil, err
		}

		// store session data for finish
		b, err := json.Marshal(
			sess,
			json.FormatNilSliceAsNull(true), // https://github.com/go-webauthn/webauthn/pull/327
		)
		if err != nil {
			return nil, err
		}
		info.SetSessionData(b)
		a.store.Do(ctx, func(s *authv1.Store) {
			s.GetSessions()[info.GetSessionId()] = info
		})
		return cred, nil
	}()
	if err != nil {
		a.o.HTTPErr(ctx, "failed to start login", err, rw, http.StatusInternalServerError)
		return
	}
	rw.Header().Set("content-type", "application/json")
	json.MarshalWrite(rw, cred)

	a.mLogins.Add(ctx, 1, metric.WithAttributes(attribute.String("phase", "start")))
}

func (a *App) loginFinish(rw http.ResponseWriter, r *http.Request) {
	ctx, span := a.o.T.Start(r.Context(), "loginFinish")
	defer span.End()

	body := map[string]any{"status": "ok"}

	info := FromContext(ctx)
	var user wanUser
	err := a.o.Region(ctx, "validate credentials", func(ctx context.Context, span trace.Span) error {
		if len(info.GetSessionData()) == 0 {
			return errors.New("no session started")
		}
		var sess webauthn.SessionData
		err := json.Unmarshal(info.GetSessionData(), &sess)
		if err != nil {
			return fmt.Errorf("unmarshal stored session data: %w", err)
		}
		parsedResponse, err := protocol.ParseCredentialRequestResponse(r)
		if err != nil {
			return fmt.Errorf("parse credential response: %w", err)
		}
		webauthnUser, _, err := a.webauthn.ValidatePasskeyLogin(a.discoverableUserHandler(ctx), sess, parsedResponse)
		if err != nil {
			return fmt.Errorf("validate passkey login: %w", err)
		}

		user = webauthnUser.(wanUser)
		return nil
	})
	if err != nil {
		a.o.HTTPErr(ctx, "failed to validate credentials", err, rw, http.StatusUnauthorized,
			slog.String("session.session_data", string(info.GetSessionData())),
		)
		return
	}

	// ok

	err = a.o.Region(ctx, "prepare new session", func(ctx context.Context, span trace.Span) error {
		token := genToken("moou_")
		tokenInfo := authv1.TokenInfo_builder{
			SessionId: &token,
			Created:   timestamppb.Now(),
			UserId:    ptr(user.u.GetUserId()),
		}.Build()

		// swap tokens
		a.store.Do(ctx, func(s *authv1.Store) {
			delete(s.GetSessions(), info.GetSessionId())
			s.GetSessions()[tokenInfo.GetSessionId()] = tokenInfo
		})

		// send it to the client
		http.SetCookie(rw, &http.Cookie{
			Name:        a.cookieName,
			Value:       tokenInfo.GetSessionId(),
			Path:        "/",
			Domain:      a.cookieDomain,
			MaxAge:      int(30 * 24 * time.Hour.Seconds()),
			Secure:      true,
			HttpOnly:    true,
			SameSite:    http.SameSiteStrictMode,
			Partitioned: true,
		})
		return nil
	})
	if err != nil {
		a.o.HTTPErr(ctx, "failed to prepare new session", err, rw, http.StatusInternalServerError)
		return
	}

	rw.Header().Set("content-type", "application/json")
	json.MarshalWrite(rw, body)

	a.mLogins.Add(ctx, 1, metric.WithAttributes(attribute.String("phase", "finish")))
}
