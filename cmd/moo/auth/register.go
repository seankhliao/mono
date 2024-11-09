package auth

import (
	"errors"
	"fmt"
	mathrand "math/rand/v2"
	"net/http"

	"github.com/go-json-experiment/json"
	"github.com/go-webauthn/webauthn/protocol"
	"github.com/go-webauthn/webauthn/webauthn"
	"go.seankhliao.com/mono/cmd/moo/auth/authv1"
)

func (a *App) registerStart(rw http.ResponseWriter, r *http.Request) {
	ctx, span := a.o.T.Start(r.Context(), "registerStart")
	defer span.End()
	create, err := func() (*protocol.CredentialCreation, error) {
		info := FromContext(ctx)

		if info.GetUserId() == 0 {
			adminToken := r.FormValue("adminToken")
			if adminToken == "" {
				return nil, fmt.Errorf("no admin token")
			}
			var ok bool
			a.store.RDo(func(s *authv1.Store) {
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
			a.store.Do(func(s *authv1.Store) {
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
				s.Users[userID] = &authv1.UserInfo{
					UserId:   ptr(userID),
					Username: ptr(username),
				}

				info.UserId = &userID

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

		var user *authv1.UserInfo
		var ok bool
		a.store.RDo(func(s *authv1.Store) {
			user, ok = s.Users[info.GetUserId()]
		})
		if !ok {
			return nil, errors.New("user not found")
		}

		create, sess, err := a.webauthn.BeginRegistration(User{user})
		if err != nil {
			return nil, err
		}

		info.SessionData, err = json.Marshal(sess)
		if err != nil {
			return nil, err
		}
		info.Credname = &credname
		a.store.Do(func(s *authv1.Store) {
			s.Sessions[info.GetSessionId()] = info
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

	json.MarshalWrite(rw, body)
}

func (a *App) registerFinish(rw http.ResponseWriter, r *http.Request) {
	ctx, span := a.o.T.Start(r.Context(), "registerFinish")
	defer span.End()
	err := func() error {
		info := FromContext(ctx)

		var user *authv1.UserInfo
		var ok bool
		a.store.RDo(func(s *authv1.Store) {
			user, ok = s.Users[info.GetUserId()]
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
		user.Creds = append(user.Creds, &authv1.Credential{
			Name: info.Credname,
			Cred: credb,
		})

		a.store.Do(func(s *authv1.Store) {
			s.Users[*user.UserId] = user
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
