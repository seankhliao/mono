package main

import (
	"context"
	_ "embed"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/maragudk/gomponents"
	"github.com/maragudk/gomponents/html"
	"go.etcd.io/bbolt"
	"go.seankhliao.com/mono/webstyle"
)

//go:embed script.js
var scriptJS string

func (a *App) index() http.Handler {
	return http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
		ctx, span := a.o.T.Start(r.Context(), "index")
		defer span.End()

		content := []gomponents.Node{
			html.H3(html.Em(gomponents.Text("auth ")), gomponents.Text("svr")),
		}

		user, sess, err := a.getActiveSession(ctx, r)
		if errors.Is(err, ErrNoSession) {
			content = append(content,
				html.H4(html.Em(gomponents.Text("login"))),
				html.P(gomponents.Text("Log in with a passkey:")),
				html.FormEl(
					html.Action("javascript:loginUser()"),
					html.Input(html.Type("submit"), html.Value("login")),
				),
				html.Script(gomponents.Raw(scriptJS)),
			)
		} else if err != nil {
			a.o.HTTPErr(ctx, "get session data", err, rw, http.StatusInternalServerError)
			return
		} else {
			knownCreds := []gomponents.Node{}
			for _, cred := range user.Creds {
				knownCreds = append(knownCreds, html.Tr(
					html.Td(gomponents.Text(hex.EncodeToString(cred.ID))),
					html.Td(gomponents.Text(cred.AttestationType)),
					html.Td(gomponents.Text(string(cred.Authenticator.Attachment))),
					html.Td(gomponents.Text(strconv.FormatUint(uint64(cred.Authenticator.SignCount), 10))),
					html.Td(gomponents.Text(fmt.Sprint(cred.Transport))),
				))
			}
			content = append(content,
				html.H4(html.Em(gomponents.Text("user ")), gomponents.Text(user.Email)),
				html.P(gomponents.Text("Credentials attached to this user:")),
				html.Table(
					html.THead(
						html.Tr(
							html.Th(gomponents.Text("cred id")),
							html.Th(gomponents.Text("attestation type")),
							html.Th(gomponents.Text("attachment")),
							html.Th(gomponents.Text("sign count")),
							html.Th(gomponents.Text("transports")),
						),
					),
					html.TBody(knownCreds...),
				),
				html.H4(html.Em(gomponents.Text("logout"))),
				html.P(
					html.Strong(gomponents.Text("session start:")),
					gomponents.Text(sess.StartTime.Format(time.DateTime)),
				),
				html.P(
					html.Strong(gomponents.Text("user agent:")),
					gomponents.Text(sess.UserAgent),
				),
				html.P(
					html.Strong(gomponents.Text("login cred:")),
					gomponents.Text(sess.LoginCredID),
				),
				html.FormEl(
					html.Action("/logout"), html.Method("post"),
					html.Input(html.Type("submit"), html.Value("logout")),
				),
				html.Script(gomponents.Raw(scriptJS)),
			)
		}

		content = append(content,
			html.H4(html.Em(gomponents.Text("register ")), gomponents.Text("user / device")),
			html.FormEl(
				html.Action("javascript:registerUser()"),
				html.Label(html.For("email"), gomponents.Text("Email:")),
				html.Input(html.Type("email"), html.ID("email"), html.Name("email")),
				html.Label(html.For("key"), gomponents.Text("Admin key:")),
				html.Input(html.Type("password"), html.ID("adminkey"), html.Name("adminkey")),
				html.Input(html.Type("submit"), html.Value("Register")),
			),
		)

		o := webstyle.NewOptions("authsvr", "auth svr", content)
		webstyle.Structured(rw, o)
	})
}

func (a *App) getActiveSession(ctx context.Context, r *http.Request) (user User, sess SessionInfo, err error) {
	wanSessCook, err := r.Cookie(AuthCookieName)
	if errors.Is(err, http.ErrNoCookie) {
		return user, sess, ErrNoSession
	} else if err != nil {
		return user, sess, fmt.Errorf("get auth cookie: %w", err)
	}

	err = a.db.View(func(tx *bbolt.Tx) error {
		bkt := tx.Bucket(bucketSession)
		rawSess := bkt.Get([]byte(wanSessCook.Value))
		if len(rawSess) == 0 {
			return ErrNoSession
		}
		err := json.Unmarshal(rawSess, &sess)
		if err != nil {
			return fmt.Errorf("unmarshal session info: %w", err)
		}

		bkt = tx.Bucket(bucketUser)
		rawUser := bkt.Get([]byte(sess.Email))
		err = json.Unmarshal(rawUser, &user)
		if err != nil {
			return fmt.Errorf("unmarshal user info: %w", err)
		}
		return nil
	})
	return user, sess, err
}
