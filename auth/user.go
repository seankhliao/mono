package auth

import (
	"bytes"
	"context"
	"errors"
	"strconv"

	"github.com/go-json-experiment/json"
	"github.com/go-webauthn/webauthn/webauthn"
	authv1 "go.seankhliao.com/mono/auth/v1"
)

var _ webauthn.User = wanUser{}

// wanUser is a wrapper around the internal user type,
// providing methods that satisfy the [webauthn.User] interface
// used for passkey authentication.
type wanUser struct {
	u           *authv1.UserInfo
	cachedCreds []webauthn.Credential
}

func (u wanUser) WebAuthnID() []byte          { return []byte(strconv.FormatInt(u.u.GetUserId(), 10)) }
func (u wanUser) WebAuthnName() string        { return u.u.GetUsername() }
func (u wanUser) WebAuthnDisplayName() string { return u.u.GetUsername() }
func (u wanUser) WebAuthnCredentials() []webauthn.Credential {
	if len(u.cachedCreds) == 0 {
		u.cachedCreds = make([]webauthn.Credential, len(u.u.GetCreds()))
		for i, b := range u.u.GetCreds() {
			json.Unmarshal(b.GetCred(), &u.cachedCreds[i])
		}
	}

	return u.cachedCreds
}

func (a *App) discoverableUserHandler(ctx context.Context) func(rawID, userHandle []byte) (user webauthn.User, err error) {
	return func(rawID, userHandle []byte) (user webauthn.User, err error) {
		var found bool

		a.store.RDo(ctx, func(s *authv1.Store) {
		loop:
			for _, u := range s.GetUsers() {
				user = wanUser{u: u}
				for _, cred := range user.WebAuthnCredentials() {
					if bytes.Equal(cred.ID, userHandle) || bytes.Equal(cred.ID, rawID) {
						found = true
						break loop
					}
				}
			}
		})

		if !found {
			return nil, errors.New("handle not found")
		}
		return user, nil
	}
}
