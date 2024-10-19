package auth

import (
	"encoding/json"
	"errors"
	"strconv"

	"github.com/go-webauthn/webauthn/webauthn"
)

// SessionID is also the cookie Value
// has a prefix of:
//   - moou_ for user tokens
//   - moox_ for anonymous tokens
//   - mooa_ for admin tokens

// UserID is identifies the user
//   - > 0 for valid users
//   - = 0 for anonymous users
//   - < 0 for admin tokens

type tokenInfoContextKey struct{}

var TokenInfoContextKey = tokenInfoContextKey{}

type User struct {
	u *UserInfo
}

func (u User) WebAuthnID() []byte          { return []byte(strconv.FormatInt(u.u.GetUserID(), 10)) }
func (u User) WebAuthnName() string        { return u.u.GetUsername() }
func (u User) WebAuthnDisplayName() string { return u.u.GetUsername() }
func (u User) WebAuthnCredentials() []webauthn.Credential {
	creds := make([]webauthn.Credential, len(u.u.Credentials))
	for i, b := range u.u.Credentials {
		json.Unmarshal(b, &creds[i])
	}
	return creds
}

func (a *App) discoverableUserHandler(rawID, userHandle []byte) (user webauthn.User, err error) {
	var u *UserInfo
	var found bool

	a.store.RLock()
	defer a.store.RUnlock()
loop:
	for _, user := range a.store.Data.Users {
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

	if !found {
		return nil, errors.New("handle not found")
	}
	return User{u}, nil
}
