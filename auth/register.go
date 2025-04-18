package auth

import (
	"encoding/json/v2"
	"errors"
	"fmt"
	mathrand "math/rand/v2"
	"net/http"

	"github.com/go-webauthn/webauthn/protocol"
	"github.com/go-webauthn/webauthn/webauthn"
	authv1 "go.seankhliao.com/mono/auth/v1"
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
				_, ok = s.GetSessions()[adminToken]
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
					_, ok := s.GetUsers()[userID]
					if !ok {
						break
					}
					userID = mathrand.Int64()
				}
				for _, user := range s.GetUsers() {
					if user.GetUsername() == username {
						err = fmt.Errorf("username in use")
						return
					}
				}
				s.GetUsers()[userID] = authv1.UserInfo_builder{
					UserId:   ptr(userID),
					Username: ptr(username),
				}.Build()

				info.SetUserId(userID)

				delete(s.GetSessions(), adminToken)
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
			user, ok = s.GetUsers()[info.GetUserId()]
		})
		if !ok {
			return nil, errors.New("user not found")
		}

		create, sess, err := a.webauthn.BeginRegistration(wanUser{u: user})
		if err != nil {
			return nil, err
		}

		b, err := json.Marshal(
			sess,
			json.FormatNilSliceAsNull(true), // https://github.com/go-webauthn/webauthn/pull/327
		)
		if err != nil {
			return nil, err
		}
		info.SetSessionData(b)
		info.SetCredName(credname)
		a.store.Do(ctx, func(s *authv1.Store) {
			s.GetSessions()[info.GetSessionId()] = info
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
			user, ok = s.GetUsers()[info.GetUserId()]
		})
		if !ok {
			return errors.New("user not found")
		}

		if !info.HasSessionData() {
			return errors.New("no session started")
		}
		var sess webauthn.SessionData
		err := json.Unmarshal(info.GetSessionData(), &sess)
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
		user.SetCreds(append(user.GetCreds(), authv1.Credential_builder{
			Name: ptr(info.GetCredName()),
			Cred: credb,
		}.Build()))

		a.store.Do(ctx, func(s *authv1.Store) {
			s.GetUsers()[user.GetUserId()] = user
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
