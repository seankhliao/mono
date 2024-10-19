package auth

import (
	"encoding/json"
	"errors"
	"fmt"
	mathrand "math/rand/v2"
	"net/http"

	"github.com/go-webauthn/webauthn/protocol"
	"github.com/go-webauthn/webauthn/webauthn"
)

func (a *App) registerStart(rw http.ResponseWriter, r *http.Request) {
	create, err := func() (*protocol.CredentialCreation, error) {
		ctx := r.Context()
		info := ctx.Value(TokenInfoContextKey).(*TokenInfo)

		if info.GetUserID() == 0 {
			adminToken := r.FormValue("adminToken")
			if adminToken == "" {
				return nil, fmt.Errorf("no admin token")
			}
			a.store.RLock()
			_, ok := a.store.Data.Sessions[adminToken]
			a.store.RUnlock()
			if !ok {
				return nil, fmt.Errorf("invalid admin token")
			}

			username := r.FormValue("username")
			if username == "" {
				return nil, fmt.Errorf("empty username")
			}

			err := func() error {
				a.store.Lock()
				defer a.store.Unlock()

				userID := mathrand.Int64()
				for {
					_, ok := a.store.Data.Users[userID]
					if !ok {
						break
					}
					userID = mathrand.Int64()
				}
				for _, user := range a.store.Data.Users {
					if user.GetUsername() == username {
						return fmt.Errorf("username in use")
					}
				}
				a.store.Data.Users[userID] = &UserInfo{
					UserID:   ptr(userID),
					Username: ptr(username),
				}

				info.UserID = &userID

				return nil
			}()
			if err != nil {
				return nil, err
			}

			a.store.Lock()
			delete(a.store.Data.Sessions, adminToken)
			a.store.Unlock()
		}

		a.store.RLock()
		user, ok := a.store.Data.Users[*info.UserID]
		a.store.RUnlock()
		if !ok {
			return nil, errors.New("user not found")
		}

		create, sess, err := a.webauthn.BeginRegistration(User{user})
		if err != nil {
			return nil, err
		}

		info.SessionData, err = json.Marshal(sess)
		a.store.Lock()
		a.store.Data.Sessions[*info.SessionID] = info
		a.store.Unlock()

		return create, nil
	}()
	rw.Header().Set("content-type", "application/json")
	var body any = create
	if err != nil {
		rw.WriteHeader(http.StatusUnauthorized)
		body = map[string]any{
			"status": "error",
			"error":  err.Error(),
		}
	}

	json.NewEncoder(rw).Encode(body)
}

func (a *App) registerFinish(rw http.ResponseWriter, r *http.Request) {
	err := func() error {
		ctx := r.Context()
		info := ctx.Value(TokenInfoContextKey).(*TokenInfo)

		a.store.RLock()
		user, ok := a.store.Data.Users[*info.UserID]
		a.store.RUnlock()
		if !ok {
			return errors.New("user not found")
		}

		if info.SessionData == nil {
			return errors.New("no session started")
		}
		var sess webauthn.SessionData
		err := json.Unmarshal(info.SessionData, &sess)
		if err != nil {
			return err
		}

		cred, err := a.webauthn.FinishRegistration(User{user}, sess, r)
		if err != nil {
			return err
		}

		credb, err := json.Marshal(cred)
		if err != nil {
			return err
		}
		user.Credentials = append(user.Credentials, credb)

		a.store.Lock()
		a.store.Data.Users[*user.UserID] = user
		a.store.Unlock()

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
