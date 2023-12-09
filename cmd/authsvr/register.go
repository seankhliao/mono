package main

import (
	"crypto/rand"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"math/big"
	"net/http"

	"github.com/go-webauthn/webauthn/protocol"
	"github.com/go-webauthn/webauthn/webauthn"
	"go.etcd.io/bbolt"
)

var ErrExisting = errors.New("existing credential")

func (a *App) registerStart() http.Handler {
	return http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
		ctx := r.Context()
		ctx, span := a.o.T.Start(ctx, "registerStart")
		defer span.End()

		adminKey := r.FormValue("adminkey")
		if adminKey != a.adminKey {
			a.jsonErr(ctx, rw, "mismatched admin key", errors.New("unauthed admin key"), http.StatusUnauthorized, struct{}{})
			return
		}

		email := r.PathValue("email")
		if email == "" {
			a.jsonErr(ctx, rw, "empty email pathvalue", errors.New("no email"), http.StatusBadRequest, struct{}{})
			return
		}

		var user User
		err := a.db.Update(func(tx *bbolt.Tx) error {
			bkt := tx.Bucket(bucketUser)
			b := bkt.Get([]byte(email))
			if len(b) == 0 {
				user.Email = email
				id, _ := rand.Int(rand.Reader, big.NewInt(math.MaxInt64))
				user.ID = id.Int64()
				b, err := json.Marshal(user)
				if err != nil {
					return fmt.Errorf("marshal new user: %w", err)
				}
				return bkt.Put([]byte(email), b)
			}
			return json.Unmarshal(b, &user)
		})
		if err != nil {
			a.jsonErr(ctx, rw, "get user from email", err, http.StatusInternalServerError, struct{}{})
			return
		}

		var exlcusions []protocol.CredentialDescriptor
		for _, cred := range user.Creds {
			exlcusions = append(exlcusions, cred.Descriptor())
		}

		data, wanSess, err := a.wan.BeginRegistration(user, webauthn.WithExclusions(exlcusions))
		if err != nil {
			a.jsonErr(ctx, rw, "webauthn begin registration", err, http.StatusInternalServerError, struct{}{})
			return
		}

		wanSessCook, err := a.storeSecret("webauthn_register_start", wanSess)
		if err != nil {
			a.jsonErr(ctx, rw, "store session cookie", err, http.StatusInternalServerError, struct{}{})
			return
		}
		http.SetCookie(rw, wanSessCook)

		a.jsonOk(ctx, rw, data)
	})
}

func (a *App) registerFinish() http.Handler {
	return http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
		ctx := r.Context()
		ctx, span := a.o.T.Start(ctx, "registerFinish")
		defer span.End()

		adminKey := r.FormValue("adminkey")
		if adminKey != a.adminKey {
			a.jsonErr(ctx, rw, "mismatched admin key", errors.New("unauthed admin key"), http.StatusUnauthorized, struct{}{})
			return
		}

		email := r.PathValue("email")
		if email == "" {
			a.jsonErr(ctx, rw, "empty email pathvalue", errors.New("no email"), http.StatusBadRequest, struct{}{})
			return
		}

		wanSessCook, err := r.Cookie("webauthn_register_start")
		if err != nil {
			a.jsonErr(ctx, rw, "get session cookie", err, http.StatusBadRequest, struct{}{})
			return
		}
		var wanSess webauthn.SessionData
		err = a.readSecret("webauthn_register_start", wanSessCook, &wanSess)
		if err != nil {
			a.jsonErr(ctx, rw, "decode session cookie", err, http.StatusBadRequest, struct{}{})
			return
		}

		err = a.db.Update(func(tx *bbolt.Tx) error {
			bkt := tx.Bucket(bucketUser)
			b := bkt.Get([]byte(email))
			var user User
			err := json.Unmarshal(b, &user)
			if err != nil {
				return fmt.Errorf("decode user: %w", err)
			}

			cred, err := a.wan.FinishRegistration(user, wanSess, r)
			if err != nil {
				return fmt.Errorf("finish registration: %w", err)
			}
			user.Creds = append(user.Creds, *cred)

			b, err = json.Marshal(user)
			if err != nil {
				return fmt.Errorf("encode user: %w", err)
			}

			err = bkt.Put([]byte(email), b)
			if err != nil {
				return fmt.Errorf("update user")
			}

			bkt = tx.Bucket(bucketCred)
			err = bkt.Put(cred.ID, []byte(email))
			if err != nil {
				return fmt.Errorf("link cred to user")
			}
			return nil
		})
		if err != nil {
			a.jsonErr(ctx, rw, "store registration", err, http.StatusInternalServerError, err)
			return
		}

		a.jsonOk(ctx, rw, struct{}{})
	})
}
