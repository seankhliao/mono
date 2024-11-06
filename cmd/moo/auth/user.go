package auth

import (
	"encoding/json"
	"errors"
	"strconv"

	"github.com/go-webauthn/webauthn/webauthn"
	"go.seankhliao.com/mono/cmd/moo/auth/authv1"
)

type User struct {
	u *authv1.UserInfo
}

func (u User) WebAuthnID() []byte          { return []byte(strconv.FormatInt(u.u.GetUserId(), 10)) }
func (u User) WebAuthnName() string        { return u.u.GetUsername() }
func (u User) WebAuthnDisplayName() string { return u.u.GetUsername() }
func (u User) WebAuthnCredentials() []webauthn.Credential {
	creds := make([]webauthn.Credential, len(u.u.Creds))
	for i, b := range u.u.Creds {
		json.Unmarshal(b.Cred, &creds[i])
	}
	return creds
}

func (a *App) discoverableUserHandler(rawID, userHandle []byte) (user webauthn.User, err error) {
	var u *authv1.UserInfo
	var found bool

	a.store.RDo(func(s *authv1.Store) {
	loop:
		for _, user := range s.Users {
			creds := User{user}.WebAuthnCredentials()
			for _, cred := range creds {
				if string(cred.ID) == string(userHandle) {
					u = user
					found = true
					break loop
				}
				if string(cred.ID) == string(rawID) {
					u = user
					found = true
					break loop
				}

			}
		}
	})

	if !found {
		return nil, errors.New("handle not found")
	}
	return User{u}, nil
}
