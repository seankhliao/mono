package auth

import (
	_ "embed"
	"net/http"
	"net/url"
	"strings"

	authv1 "go.seankhliao.com/mono/auth/v1"
	"go.seankhliao.com/mono/webstyle"
	"maragu.dev/gomponents"
	"maragu.dev/gomponents/html"
)

//go:embed script.js
var scriptJS string

func (a *App) homepage(rw http.ResponseWriter, r *http.Request) {
	ctx, span := a.o.T.Start(r.Context(), "homepage")
	defer span.End()

	info := FromContext(ctx)
	if info.GetUserId() <= 0 {
		returnTo := r.FormValue("return")
		if returnTo != "" {
			u, err := url.Parse(returnTo)
			if err != nil {
				returnTo = ""
			} else if !strings.HasSuffix(u.Host, a.cookieDomain) {
				returnTo = ""
			} else {
				returnTo = u.String()
			}
		}

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

				html.Input(html.Type("text"), html.ID("return"), html.Name("return"), html.Value(returnTo), html.Hidden("hidden")),

				html.Label(html.For("username"), gomponents.Text("username")),
				html.Input(html.Type("text"), html.ID("username"), html.Name("username"), html.Placeholder("a username"), html.Required()),

				html.Label(html.For("adminToken"), gomponents.Text("admin token: mooa_xxxxxx...")),
				html.Input(html.Type("password"), html.ID("adminToken"), html.Name("adminToken"), html.Required()),

				html.Label(html.For("credname"), gomponents.Text("credential name")),
				html.Input(html.Type("credname"), html.ID("credname"), html.Name("credname"), html.Required()),

				html.Input(html.Type("submit"), html.ID("register"), html.Value("begin registration")),
			),
		}))
		return
	}

	var user *authv1.UserInfo
	a.store.RDo(ctx, func(s *authv1.Store) {
		user = s.Users[info.GetUserId()]
	})

	var credIDs []gomponents.Node
	for _, cred := range user.Creds {
		credIDs = append(credIDs, html.Li(gomponents.Text(cred.GetName())))
	}

	webstyle.Structured(rw, webstyle.NewOptions("hello "+user.GetUsername(), "auth", []gomponents.Node{
		html.Script(gomponents.Raw(scriptJS)),
		html.H3(html.Em(gomponents.Text("hello ")), gomponents.Text(user.GetUsername())),
		html.Ul(
			html.Li(html.Em(gomponents.Text("User ID:")), gomponents.Textf("%v", user.GetUserId())),
		),

		html.H4(gomponents.Text("account details")),
		html.Form(
			html.Action("/update"), html.Method("post"),

			html.Label(html.For("username"), gomponents.Text("username")),
			html.Input(html.Type("text"), html.ID("username"), html.Name("username"), html.Value(user.GetUsername()), html.Required()),

			html.Input(html.Type("submit"), html.Value("Update")),
		),

		html.H4(gomponents.Text("register new credential")),
		html.Ul(credIDs...),
		html.Form(
			html.Action("javascript:register()"),

			html.Input(html.Type("password"), html.ID("adminToken"), html.Name("adminToken"), html.Hidden("hidden"), html.Value("placeholder")),

			html.Label(html.For("credname"), gomponents.Text("credential name")),
			html.Input(html.Type("credname"), html.ID("credname"), html.Name("credname"), html.Required()),

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
	ctx, span := a.o.T.Start(r.Context(), "update")
	defer span.End()
	info := FromContext(ctx)

	err := r.ParseForm()
	if err != nil {
		a.o.HTTPErr(ctx, "failed update", err, rw, http.StatusInternalServerError)
		return
	}

	a.store.Do(ctx, func(s *authv1.Store) {
		user := s.Users[*info.UserId]
		user.Username = ptr(r.FormValue("username"))
		s.Users[*info.UserId] = user
	})

	http.Redirect(rw, r, "/", http.StatusFound)
}

func (a *App) logoutPage(rw http.ResponseWriter, r *http.Request) {
	ctx, span := a.o.T.Start(r.Context(), "logoutPage")
	defer span.End()
	info := FromContext(ctx)

	var user *authv1.UserInfo
	a.store.RDo(ctx, func(s *authv1.Store) {
		user = s.Users[*info.UserId]
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
	ctx, span := a.o.T.Start(r.Context(), "logoutAction")
	defer span.End()
	info := FromContext(ctx)

	a.store.Do(ctx, func(s *authv1.Store) {
		delete(s.Sessions, info.GetSessionId())
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
