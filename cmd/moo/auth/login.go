package auth

import (
	"crypto/rand"
	_ "embed"
	"encoding/base32"
	"errors"
	"net/http"
	"time"

	"github.com/go-json-experiment/json"
	"github.com/go-webauthn/webauthn/protocol"
	"github.com/go-webauthn/webauthn/webauthn"
	"go.seankhliao.com/mono/cmd/moo/auth/authv1"
	"google.golang.org/protobuf/types/known/timestamppb"
)

func (a *App) loginStart(rw http.ResponseWriter, r *http.Request) {
	ctx, span := a.o.T.Start(r.Context(), "loginStart")
	defer span.End()
	cred, err := func() (*protocol.CredentialAssertion, error) {
		info := FromContext(ctx)

		cred, sess, err := a.webauthn.BeginDiscoverableLogin()
		if err != nil {
			return nil, err
		}

		// store session data for finish
		info.SessionData, _ = json.Marshal(sess)
		a.store.Do(func(s *authv1.Store) {
			s.Sessions[*info.SessionId] = info
		})
		return cred, nil
	}()
	rw.Header().Set("content-type", "application/json")
	var body any = cred
	if err != nil {
		rw.WriteHeader(http.StatusUnauthorized)
		body = map[string]any{
			"status": "error",
			"error":  err.Error(),
		}
	}
	json.MarshalWrite(rw, body)
}

func (a *App) loginFinish(rw http.ResponseWriter, r *http.Request) {
	ctx, span := a.o.T.Start(r.Context(), "loginFinish")
	defer span.End()
	err := func() error {
		info := FromContext(ctx)

		if info.SessionData == nil {
			return errors.New("no session started")
		}
		var sess webauthn.SessionData
		err := json.Unmarshal(info.SessionData, &sess)
		if err != nil {
			return err
		}
		parsedResponse, err := protocol.ParseCredentialRequestResponse(r)
		if err != nil {
			return err
		}
		webauthnUser, _, err := a.webauthn.ValidatePasskeyLogin(a.discoverableUserHandler, sess, parsedResponse)
		if err != nil {
			return err
		}

		// ok

		user := webauthnUser.(User)

		// generate a new named token
		rawToken := make([]byte, 16)
		rand.Read(rawToken)
		token := []byte("moou_")
		token = base32.StdEncoding.AppendEncode(token, rawToken)
		tokenInfo := &authv1.TokenInfo{
			SessionId: ptr(string(token)),
			Created:   timestamppb.Now(),
			UserId:    user.u.UserId,
		}

		// swap tokens
		a.store.Do(func(s *authv1.Store) {
			delete(s.Sessions, *info.SessionId)
			s.Sessions[tokenInfo.GetSessionId()] = tokenInfo
		})

		// send it to the client
		http.SetCookie(rw, &http.Cookie{
			Name:        a.cookieName,
			Value:       *tokenInfo.SessionId,
			Path:        "/",
			Domain:      a.cookieDomain,
			MaxAge:      int(30 * 24 * time.Hour.Seconds()),
			Secure:      true,
			HttpOnly:    true,
			SameSite:    http.SameSiteStrictMode,
			Partitioned: true,
		})
		return nil
	}()
	rw.Header().Set("content-type", "application/json")
	body := map[string]any{"status": "ok"}
	if err != nil {
		rw.WriteHeader(http.StatusUnauthorized)
		body = map[string]any{
			"status": "error",
			"error":  err.Error(),
		}
	}

	json.MarshalWrite(rw, body)
}
