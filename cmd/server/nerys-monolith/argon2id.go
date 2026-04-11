package main

import (
	"context"
	"encoding/hex"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"strings"

	"go.seankhliao.com/mono/run"
	"golang.org/x/crypto/argon2"
)

var _ run.Simpler = &Argon2ID{}

type Argon2ID struct {
	userID string
}

// Flags implements [run.Simpler].
func (a *Argon2ID) Flags(fset *flag.FlagSet, args **[]string) error {
	fset.StringVar(&a.userID, "user", "", "user id (email)")
	return nil
}

// Run implements [run.Simpler].
func (a *Argon2ID) Run(ctx context.Context, stdin io.Reader, stdout io.Writer, stderr io.Writer, fsys fs.FS) error {
	if a.userID == "" {
		return fmt.Errorf("empty user id")
	}
	var password string
	_, err := fmt.Fscan(stdin, &password)
	if err != nil {
		return fmt.Errorf("read password from stdin")
	}
	password = strings.TrimSpace(password)
	if len(password) == 0 {
		return fmt.Errorf("no password provided")
	} else if len(password) < 12 {
		return fmt.Errorf("password too short < 12")
	}

	got := argon2.IDKey([]byte(password), []byte(a.userID), 1, 64*1024, 4, 32)
	fmt.Println(hex.EncodeToString(got))
	return nil
}
