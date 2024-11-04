package auth

import (
	"context"
	"crypto/rand"
	_ "embed"
	"encoding/base32"
	"encoding/json"
	"errors"
	"net/http"
	"time"

	"github.com/go-webauthn/webauthn/protocol"
	"github.com/go-webauthn/webauthn/webauthn"
	"google.golang.org/protobuf/types/known/timestamppb"
)

func (a *App) requestUser(ctx context.Context, r *http.Request) (info *TokenInfo, ok bool) {
	c, err := r.Cookie(a.cookieName)
	if err != nil {
		return nil, false
	}

	a.store.RDo(func(s *Store) {
		info, ok = s.Sessions[c.Value]
	})
	return
}

func (a *App) loginStart(rw http.ResponseWriter, r *http.Request) {
	ctx, span := a.o.T.Start(r.Context(), "loginStart")
	defer span.End()
	cred, err := func() (*protocol.CredentialAssertion, error) {
		info := ctx.Value(TokenInfoContextKey).(*TokenInfo)

		cred, sess, err := a.webauthn.BeginDiscoverableLogin()
		if err != nil {
			return nil, err
		}

		// store session data for finish
		info.SessionData, _ = json.Marshal(sess)
		a.store.Do(func(s *Store) {
			s.Sessions[*info.SessionID] = info
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
	json.NewEncoder(rw).Encode(body)
}

func (a *App) loginFinish(rw http.ResponseWriter, r *http.Request) {
	ctx, span := a.o.T.Start(r.Context(), "loginFinish")
	defer span.End()
	err := func() error {
		info := ctx.Value(TokenInfoContextKey).(*TokenInfo)

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
		tokenInfo := TokenInfo{
			SessionID: ptr(string(token)),
			Created:   timestamppb.Now(),
			UserID:    user.u.UserID,
		}

		// swap tokens
		a.store.Do(func(s *Store) {
			delete(s.Sessions, *info.SessionID)
			s.Sessions[tokenInfo.GetSessionID()] = &tokenInfo
		})

		// send it to the client
		http.SetCookie(rw, &http.Cookie{
			Name:        a.cookieName,
			Value:       *tokenInfo.SessionID,
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

	json.NewEncoder(rw).Encode(body)
}
