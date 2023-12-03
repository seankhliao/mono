package main

import (
	"github.com/go-webauthn/webauthn/webauthn"
)

var (
	bucketUser = []byte(`user`)
	bucketCred = []byte(`credential`)
)

var _ webauthn.User = &User{}

type User struct {
	ID    int64
	Email string
	Creds []webauthn.Credential
}

// might fail if len(email) > 64
func (u User) WebAuthnID() []byte                         { return []byte(u.Email) }
func (u User) WebAuthnName() string                       { return u.Email }
func (u User) WebAuthnDisplayName() string                { return u.Email }
func (u User) WebAuthnCredentials() []webauthn.Credential { return u.Creds }
func (u User) WebAuthnIcon() string                       { return "" }
