package auth

import (
	"errors"
	"fmt"
	mathrand "math/rand/v2"
	"net/http"

	"github.com/go-json-experiment/json"
	"github.com/go-webauthn/webauthn/protocol"
	"github.com/go-webauthn/webauthn/webauthn"
	"go.seankhliao.com/mono/auth/authv1"
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
			a.store.RDo(ctx, func(s *authv1.Store) {
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
			a.store.Do(ctx, func(s *authv1.Store) {
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
		a.store.RDo(ctx, func(s *authv1.Store) {
			user, ok = s.Users[info.GetUserId()]
		})
		if !ok {
			return nil, errors.New("user not found")
		}

		create, sess, err := a.webauthn.BeginRegistration(wanUser{u: user})
		if err != nil {
			return nil, err
		}

		info.SessionData, err = json.Marshal(
			sess,
			json.FormatNilSliceAsNull(true), // https://github.com/go-webauthn/webauthn/pull/327
		)
		if err != nil {
			return nil, err
		}
		info.Credname = &credname
		a.store.Do(ctx, func(s *authv1.Store) {
			s.Sessions[info.GetSessionId()] = info
		})

		return create, nil
	}()
	if err != nil {
		a.o.HTTPErr(ctx, "failed to being registration", err, rw, http.StatusInternalServerError)
		return
	}

	rw.Header().Set("content-type", "application/json")
	json.MarshalWrite(rw, create)
}

func (a *App) registerFinish(rw http.ResponseWriter, r *http.Request) {
	ctx, span := a.o.T.Start(r.Context(), "registerFinish")
	defer span.End()
	err := func() error {
		info := FromContext(ctx)

		var user *authv1.UserInfo
		var ok bool
		a.store.RDo(ctx, func(s *authv1.Store) {
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

		cred, err := a.webauthn.FinishRegistration(wanUser{u: user}, sess, r)
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

		a.store.Do(ctx, func(s *authv1.Store) {
			s.Users[*user.UserId] = user
		})

		return nil
	}()
	if err != nil {
		a.o.HTTPErr(ctx, "failed to complete registration", err, rw, http.StatusInternalServerError)
		return
	}

	rw.Header().Set("content-type", "application/json")
	json.MarshalWrite(rw, map[string]any{"status": "ok"})
}
