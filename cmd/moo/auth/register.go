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
			var ok bool
			a.store.RDo(func(s *Store) {
				_, ok = s.Sessions[adminToken]
			})
			if !ok {
				return nil, fmt.Errorf("invalid admin token")
			}

			username := r.FormValue("username")
			if username == "" {
				return nil, fmt.Errorf("empty username")
			}

			var err error
			a.store.Do(func(s *Store) {
				userID := mathrand.Int64()
				for {
					_, ok := s.Users[userID]
					if !ok {
						break
					}
					userID = mathrand.Int64()
				}
				for _, user := range s.Users {
					if user.GetUsername() == username {
						err = fmt.Errorf("username in use")
						return
					}
				}
				s.Users[userID] = &UserInfo{
					UserID:   ptr(userID),
					Username: ptr(username),
				}

				info.UserID = &userID

				delete(s.Sessions, adminToken)
			})
			if err != nil {
				return nil, err
			}
		}

		credname := r.FormValue("credname")
		if credname == "" {
			return nil, errors.New("credential name not given")
		}

		var user *UserInfo
		var ok bool
		a.store.RDo(func(s *Store) {
			user, ok = s.Users[info.GetUserID()]
		})
		if !ok {
			return nil, errors.New("user not found")
		}

		create, sess, err := a.webauthn.BeginRegistration(User{user})
		if err != nil {
			return nil, err
		}

		info.SessionData, err = json.Marshal(sess)
		info.Credname = &credname
		a.store.Do(func(s *Store) {
			s.Sessions[info.GetSessionID()] = info
		})

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

		var user *UserInfo
		var ok bool
		a.store.RDo(func(s *Store) {
			user, ok = s.Users[info.GetUserID()]
		})
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
		user.Creds = append(user.Creds, &Credential{
			Name: info.Credname,
			Cred: credb,
		})

		a.store.Do(func(s *Store) {
			s.Users[*user.UserID] = user
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
