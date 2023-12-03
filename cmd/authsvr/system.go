package main

import (
	"context"
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strings"

	"go.etcd.io/bbolt"
)

var (
	bucketSystem = []byte(`system`)
	keyCookieKey = []byte(`cookie-key`)
)

var ErrNameMismatch = errors.New("mismatched context")

func (a *App) ensureCookieKey(ctx context.Context) error {
	err := a.db.Update(func(tx *bbolt.Tx) error {
		bkt := tx.Bucket(bucketSystem)
		key := bkt.Get(keyCookieKey)
		if len(key) != 32 {
			key = make([]byte, 32)
			_, err := rand.Read(key)
			if err != nil {
				return fmt.Errorf("generate new cookie-key: %w", err)
			}
			err = bkt.Put(keyCookieKey, key)
			if err != nil {
				return fmt.Errorf("save cookie-key: %w", err)
			}
		}
		block, err := aes.NewCipher(key)
		if err != nil {
			return fmt.Errorf("use cookie-key for aes cipher")
		}
		aead, err := cipher.NewGCM(block)
		if err != nil {
			return fmt.Errorf("create gcm cipher: %w", err)
		}

		a.aead = aead
		return nil
	})
	if err != nil {
		return fmt.Errorf("ensure cookie-key: %w", err)
	}
	return nil
}

func (a *App) readSecret(name string, cookie *http.Cookie, out any) error {
	if cookie.Name != name {
		return ErrNameMismatch
	}
	nonce64, sealed64, ok := strings.Cut(cookie.Value, ".")
	if !ok {
		return fmt.Errorf("expected nonce.sealed")
	}
	nonce, err := base64.RawURLEncoding.DecodeString(nonce64)
	if err != nil {
		return fmt.Errorf("decode nonce: %w", err)
	}
	sealed, err := base64.RawURLEncoding.DecodeString(sealed64)
	if err != nil {
		return fmt.Errorf("decode sealed date: %w", err)
	}
	b, err := a.aead.Open(nil, nonce, sealed, []byte(name))
	if err != nil {
		return fmt.Errorf("decrypt data: %w", err)
	}
	err = json.Unmarshal(b, out)
	if err != nil {
		return fmt.Errorf("unmarshal data: %w", err)
	}
	return nil
}

func (a *App) storeSecret(name string, val any) (*http.Cookie, error) {
	b, err := json.Marshal(val)
	if err != nil {
		return nil, fmt.Errorf("marshal data: %w", err)
	}
	nonce := make([]byte, a.aead.NonceSize())
	_, err = rand.Read(nonce)
	if err != nil {
		return nil, fmt.Errorf("encrypt data: %w", err)
	}
	sealed := a.aead.Seal(nil, nonce, b, []byte(name))
	cookieVal := base64.RawURLEncoding.EncodeToString(nonce) + "." + base64.RawURLEncoding.EncodeToString(sealed)
	return &http.Cookie{
		Name:     name,
		Value:    cookieVal,
		Path:     "/",
		HttpOnly: true,
		Secure:   true,
		SameSite: http.SameSiteStrictMode,
	}, nil
}
