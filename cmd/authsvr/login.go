package main

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/go-webauthn/webauthn/webauthn"
	"go.etcd.io/bbolt"
)

const (
	AuthCookieName = "authsvr_session"
)

func (a *App) logout() http.Handler {
	return http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
		ctx, span := a.o.T.Start(r.Context(), "logout")
		defer span.End()

		wanSessCook, err := r.Cookie(AuthCookieName)
		if err != nil {
			a.o.HTTPErr(ctx, "get auth cookie", err, rw, http.StatusBadRequest)
			return
		}

		err = a.db.Update(func(tx *bbolt.Tx) error {
			bkt := tx.Bucket(bucketSession)
			return bkt.Delete([]byte(wanSessCook.Value))
		})
		if err != nil {
			a.o.HTTPErr(ctx, "clear session store", err, rw, http.StatusInternalServerError)
			return
		}

		wanSessCook.MaxAge = -1
		http.SetCookie(rw, wanSessCook)

		http.Redirect(rw, r, "/", http.StatusSeeOther)
	})
}

func (a *App) startLogin() http.Handler {
	return http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
		ctx, span := a.o.T.Start(r.Context(), "startLogin")
		defer span.End()

		data, wanSess, err := a.wan.BeginDiscoverableLogin()
		if err != nil {
			a.jsonErr(ctx, rw, "webauthn begin login", err, http.StatusInternalServerError, struct{}{})
			return
		}

		wanSessCook, err := a.storeSecret("webauthn_login_start", wanSess)
		if err != nil {
			a.jsonErr(ctx, rw, "store session data", err, http.StatusInternalServerError, struct{}{})
			return
		}
		http.SetCookie(rw, wanSessCook)

		a.jsonOk(ctx, rw, data)
	})
}

func (a *App) finishLogin() http.Handler {
	return http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
		ctx, span := a.o.T.Start(r.Context(), "finishLogin")
		defer span.End()

		wanSessCook, err := r.Cookie("webauthn_login_start")
		if err != nil {
			a.jsonErr(ctx, rw, "get session cookie", err, http.StatusBadRequest, struct{}{})
			return
		}
		var wanSess webauthn.SessionData
		err = a.readSecret("webauthn_login_start", wanSessCook, &wanSess)
		if err != nil {
			a.jsonErr(ctx, rw, "read session cookie", err, http.StatusBadRequest, struct{}{})
			return
		}

		// check
		// rawID == credential id
		// userHandle == user.id in creation request (from user.WebAuthnID)
		handler := func(rawID, userHandle []byte) (webauthn.User, error) {
			var user User
			err := a.db.View(func(tx *bbolt.Tx) error {
				bkt := tx.Bucket(bucketUser)
				b := bkt.Get(userHandle)
				err := json.Unmarshal(b, &user)
				if err != nil {
					return fmt.Errorf("decode user data: %w", err)
				}
				return nil
			})
			return user, err
		}
		cred, err := a.wan.FinishDiscoverableLogin(handler, wanSess, r)
		if err != nil {
			a.jsonErr(ctx, rw, "webauthn finish login", err, http.StatusBadRequest, struct{}{})
			return
		}

		if cred.Authenticator.CloneWarning {
			a.jsonErr(ctx, rw, "cloned authenticator", err, http.StatusBadRequest, struct{}{})
			return
		}

		rawSessToken := make([]byte, 32)
		rand.Read(rawSessToken)
		sessToken := hex.EncodeToString(rawSessToken)
		http.SetCookie(rw, &http.Cookie{
			Name:     AuthCookieName,
			Value:    sessToken,
			Path:     "/",
			Domain:   a.cookieDomain,
			HttpOnly: true,
			Secure:   true,
			SameSite: http.SameSiteLaxMode,
		})

		err = a.db.Update(func(tx *bbolt.Tx) error {
			bkt := tx.Bucket(bucketCred)
			email := bkt.Get(cred.ID)
			bkt = tx.Bucket(bucketUser)
			b := bkt.Get(email)
			var user User
			err := json.Unmarshal(b, &user)
			if err != nil {
				return fmt.Errorf("decode user data: %w", err)
			}
			for i := range user.Creds {
				if string(user.Creds[i].ID) == string(cred.ID) {
					user.Creds[i].Authenticator.SignCount = cred.Authenticator.SignCount
					break
				}
			}
			b, err = json.Marshal(user)
			if err != nil {
				return fmt.Errorf("encode user data: %w", err)
			}
			err = bkt.Put(email, b)
			if err != nil {
				return fmt.Errorf("update user data: %w", err)
			}

			info := SessionInfo{
				UserID:    user.ID,
				Email:     user.Email,
				StartTime: time.Now(),
				UserAgent: r.UserAgent(),
			}
			b, err = json.Marshal(info)
			if err != nil {
				return fmt.Errorf("encode sesion info: %w", err)
			}

			bkt = tx.Bucket(bucketSession)
			err = bkt.Put([]byte(sessToken), b)
			if err != nil {
				return fmt.Errorf("store session token: %w", err)
			}

			return nil
		})
		if err != nil {
			a.jsonErr(ctx, rw, "create new session", err, http.StatusBadRequest, struct{}{})
			return
		}

		a.jsonOk(ctx, rw, struct{}{})
	})
}
