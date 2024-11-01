package auth

import (
	"crypto/rand"
	_ "embed"
	"encoding/base32"
	"net/http"
	"time"

	"go.seankhliao.com/mono/webstyle"
	"google.golang.org/protobuf/types/known/timestamppb"
	"maragu.dev/gomponents"
	"maragu.dev/gomponents/html"
)

//go:embed script.js
var scriptJS string

func (a *App) homepage(rw http.ResponseWriter, r *http.Request) {
	info, ok := a.requestUser(r)
	if !ok || info.GetUserID() <= 0 {
		// generate a new anonymous token
		rawToken := make([]byte, 16)
		rand.Read(rawToken)
		token := []byte("moox_")
		token = base32.StdEncoding.AppendEncode(token, rawToken)
		tokenInfo := TokenInfo{
			SessionID: ptr(string(token)),
			Created:   timestamppb.Now(),
		}

		// store it
		a.store.Do(func(s *Store) {
			s.Sessions[tokenInfo.GetSessionID()] = &tokenInfo
		})

		// send it to the client
		http.SetCookie(rw, &http.Cookie{
			Name:        a.cookieName,
			Value:       tokenInfo.GetSessionID(),
			Path:        "/",
			Domain:      a.cookieDomain,
			MaxAge:      int(time.Hour.Seconds()),
			Secure:      true,
			HttpOnly:    true,
			SameSite:    http.SameSiteStrictMode,
			Partitioned: true,
		})

		webstyle.Structured(rw, webstyle.NewOptions("log in?", "auth", []gomponents.Node{
			html.Script(gomponents.Raw(scriptJS)),
			html.H3(gomponents.Text("log in?")),
			html.Form(
				html.Action("javascript:login()"),

				html.Input(html.Type("submit"), html.ID("login"), html.Value("passkey login"), html.ID("start-login")),
			),

			html.H4(gomponents.Text("register")),
			html.Form(
				html.Action("javascript:register()"),

				html.Label(html.For("username"), gomponents.Text("username")),
				html.Input(html.Type("text"), html.ID("username"), html.Name("username"), html.Placeholder("a username")),

				html.Label(html.For("adminToken"), gomponents.Text("admin token: mooa_xxxxxx...")),
				html.Input(html.Type("password"), html.ID("adminToken"), html.Name("adminToken")),

				html.Input(html.Type("submit"), html.ID("register"), html.Value("begin registration")),
			),
		}))
		return
	}

	var user *UserInfo
	a.store.RDo(func(s *Store) {
		user = s.Users[info.GetUserID()]
	})

	webstyle.Structured(rw, webstyle.NewOptions("hello "+user.GetUsername(), "auth", []gomponents.Node{
		html.Script(gomponents.Raw(scriptJS)),
		html.H3(html.Em(gomponents.Text("hello ")), gomponents.Text(user.GetUsername())),

		html.H4(gomponents.Text("account details")),
		html.Form(
			html.Action("/update"), html.Method("post"),

			html.Label(html.For("username"), gomponents.Text("username")),
			html.Input(html.Type("text"), html.ID("username"), html.Name("username")),

			html.Input(html.Type("submit"), html.Value("Update")),
		),

		html.H4(gomponents.Text("register new credential")),
		html.Form(
			html.Action("javascript:register()"),

			html.Input(html.Type("submit"), html.ID("register"), html.Value("begin registration")),
		),

		html.H4(gomponents.Text("log out")),
		html.Form(
			html.Method("post"), html.Action("/logout"),
			html.Input(html.Type("submit"), html.Value("Logout")),
		),
	}))
}

func (a *App) update(rw http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	info := ctx.Value(TokenInfoContextKey).(*TokenInfo)

	err := r.ParseForm()
	if err != nil {
		http.Error(rw, err.Error(), http.StatusBadRequest)
		return
	}

	a.store.Do(func(s *Store) {
		user := s.Users[*info.UserID]
		user.Username = ptr(r.FormValue("username"))
		s.Users[*info.UserID] = user
	})

	http.Redirect(rw, r, "/", http.StatusFound)
}

func (a *App) logoutPage(rw http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	info := ctx.Value(TokenInfoContextKey).(*TokenInfo)

	var user *UserInfo
	a.store.RDo(func(s *Store) {
		user = s.Users[*info.UserID]
	})

	webstyle.Structured(rw, webstyle.NewOptions("end this session", "logout", []gomponents.Node{
		html.H3(gomponents.Text("Log out?")),
		gomponents.Text("hello " + user.GetUsername()),
		html.Form(
			html.Method("post"), html.Action("/logout"),
			html.Input(html.Type("submit"), html.Value("Logout")),
		),
	}))
}

func (a *App) logoutAction(rw http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	info := ctx.Value(TokenInfoContextKey).(*TokenInfo)

	a.store.Do(func(s *Store) {
		delete(s.Sessions, info.GetSessionID())
	})

	http.SetCookie(rw, &http.Cookie{
		Name:        a.cookieName,
		Value:       "",
		Path:        "/",
		Domain:      a.cookieDomain,
		MaxAge:      -1,
		Secure:      true,
		HttpOnly:    true,
		SameSite:    http.SameSiteStrictMode,
		Partitioned: true,
	})
	http.Redirect(rw, r, "/", http.StatusFound)
}
