package auth

import (
	"context"
	"crypto/rand"
	_ "embed"
	"encoding/base32"
	"encoding/json"
	"errors"
	"fmt"
	mathrand "math/rand/v2"
	"net/http"
	"slices"
	"strconv"
	"sync"
	"time"

	"github.com/go-webauthn/webauthn/protocol"
	"github.com/go-webauthn/webauthn/webauthn"
	"github.com/maragudk/gomponents"
	"github.com/maragudk/gomponents/html"
	"go.seankhliao.com/mono/webstyle"
	"go.seankhliao.com/mono/yrun"
)

//go:embed script.js
var scriptJS string

// TokenInfo holds information about the current session
type TokenInfo struct {
	// SessionID is also the cookie Value
	// has a prefix of:
	//   - moou_ for user tokens
	//   - moox_ for anonymous tokens
	//   - mooa_ for admin tokens
	SessionID string
	Created   time.Time

	// UserID is identifies the user
	//   - > 0 for valid users
	//   - = 0 for anonymous users
	//   - < 0 for admin tokens
	UserID int64

	// for registering a new webauthn token
	webauthnSess *webauthn.SessionData
}

type tokenInfoContextKey struct{}

var TokenInfoContextKey = tokenInfoContextKey{}

// Config from a config file
type Config struct {
	Host         string
	CookieDomain string
	CookieName   string
}

type App struct {
	host         string
	cookieName   string
	cookieDomain string

	webauthn *webauthn.WebAuthn

	sessionTokenMu sync.Mutex
	sessionTokens  map[string]TokenInfo

	usersMu sync.Mutex
	users   map[int64]userInfo
}

type userInfo struct {
	UserID   int64
	Username string
	creds    []webauthn.Credential
}

func (u userInfo) WebAuthnID() []byte                         { return []byte(strconv.FormatInt(u.UserID, 10)) }
func (u userInfo) WebAuthnName() string                       { return u.Username }
func (u userInfo) WebAuthnDisplayName() string                { return u.Username }
func (u userInfo) WebAuthnCredentials() []webauthn.Credential { return slices.Clone(u.creds) }

func New(c Config, o yrun.O11y) (*App, error) {
	a := &App{
		host:          c.Host,
		cookieName:    c.CookieName,
		cookieDomain:  c.CookieDomain,
		sessionTokens: make(map[string]TokenInfo),
		users:         make(map[int64]userInfo),
	}

	var err error
	t := true
	a.webauthn, err = webauthn.New(&webauthn.Config{
		RPID:          c.Host,
		RPDisplayName: c.Host,
		RPOrigins: []string{
			"https://" + c.Host,
		},
		AuthenticatorSelection: protocol.AuthenticatorSelection{
			RequireResidentKey: &t,
			ResidentKey:        protocol.ResidentKeyRequirementRequired,
		},
	})
	if err != nil {
		return nil, err
	}

	return a, nil
}

func (a *App) requestUser(r *http.Request) (TokenInfo, bool) {
	c, err := r.Cookie(a.cookieName)
	if err != nil {
		return TokenInfo{}, false
	}

	a.sessionTokenMu.Lock()
	info, ok := a.sessionTokens[c.Value]
	a.sessionTokenMu.Unlock()
	if !ok {
		return TokenInfo{}, false
	}
	return info, true
}

func (a *App) homepage(rw http.ResponseWriter, r *http.Request) {
	info, ok := a.requestUser(r)
	if !ok || info.UserID <= 0 {
		// generate a new anonymous token
		rawToken := make([]byte, 16)
		rand.Read(rawToken)
		token := []byte("moox_")
		token = base32.StdEncoding.AppendEncode(token, rawToken)
		tokenInfo := TokenInfo{
			SessionID: string(token),
			Created:   time.Now(),
		}

		// store it
		a.sessionTokenMu.Lock()
		a.sessionTokens[tokenInfo.SessionID] = tokenInfo
		a.sessionTokenMu.Unlock()

		// send it to the client
		http.SetCookie(rw, &http.Cookie{
			Name:        a.cookieName,
			Value:       tokenInfo.SessionID,
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

	a.usersMu.Lock()
	user := a.users[info.UserID]
	a.usersMu.Unlock()

	webstyle.Structured(rw, webstyle.NewOptions("hello "+user.Username, "auth", []gomponents.Node{
		html.Script(gomponents.Raw(scriptJS)),
		html.H3(html.Em(gomponents.Text("hello ")), gomponents.Text(user.Username)),

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
	info := ctx.Value(TokenInfoContextKey).(TokenInfo)

	err := r.ParseForm()
	if err != nil {
		http.Error(rw, err.Error(), http.StatusBadRequest)
		return
	}

	func() {
		a.usersMu.Lock()
		defer a.usersMu.Unlock()

		user := a.users[info.UserID]
		user.Username = r.FormValue("username")
		a.users[info.UserID] = user
	}()

	http.Redirect(rw, r, "/", http.StatusFound)
}

func (a *App) loginStart(rw http.ResponseWriter, r *http.Request) {
	cred, err := func() (*protocol.CredentialAssertion, error) {
		ctx := r.Context()
		info := ctx.Value(TokenInfoContextKey).(TokenInfo)

		cred, sess, err := a.webauthn.BeginDiscoverableLogin()
		if err != nil {
			return nil, err
		}

		// store session data for finish
		info.webauthnSess = sess
		a.sessionTokenMu.Lock()
		a.sessionTokens[info.SessionID] = info
		a.sessionTokenMu.Unlock()
		return cred, nil
	}()
	rw.Header().Set("content-type", "application/json")
	var body any = cred
	if err != nil {
		rw.WriteHeader(http.StatusUnauthorized)
		body = map[string]any{
			"status": "error",
			"error":  err.Error(),
		}
	}
	json.NewEncoder(rw).Encode(body)
}

func (a *App) loginFinish(rw http.ResponseWriter, r *http.Request) {
	err := func() error {
		ctx := r.Context()
		info := ctx.Value(TokenInfoContextKey).(TokenInfo)

		if info.webauthnSess == nil {
			return errors.New("no session started")
		}
		parsedResponse, err := protocol.ParseCredentialRequestResponse(r)
		if err != nil {
			return err
		}
		webauthnUser, _, err := a.webauthn.ValidatePasskeyLogin(a.discoverableUserHandler, *info.webauthnSess, parsedResponse)
		if err != nil {
			return err
		}

		// ok

		user := webauthnUser.(userInfo)

		// generate a new named token
		rawToken := make([]byte, 16)
		rand.Read(rawToken)
		token := []byte("moou_")
		token = base32.StdEncoding.AppendEncode(token, rawToken)
		tokenInfo := TokenInfo{
			SessionID: string(token),
			Created:   time.Now(),
			UserID:    user.UserID,
		}

		// swap tokens
		a.sessionTokenMu.Lock()
		delete(a.sessionTokens, info.SessionID)
		a.sessionTokens[tokenInfo.SessionID] = tokenInfo
		a.sessionTokenMu.Unlock()

		// send it to the client
		http.SetCookie(rw, &http.Cookie{
			Name:        a.cookieName,
			Value:       tokenInfo.SessionID,
			Path:        "/",
			Domain:      a.cookieDomain,
			MaxAge:      int(30 * 24 * time.Hour.Seconds()),
			Secure:      true,
			HttpOnly:    true,
			SameSite:    http.SameSiteStrictMode,
			Partitioned: true,
		})
		return nil
	}()
	rw.Header().Set("content-type", "application/json")
	body := map[string]any{"status": "ok"}
	if err != nil {
		rw.WriteHeader(http.StatusUnauthorized)
		body = map[string]any{
			"status": "error",
			"error":  err.Error(),
		}
	}

	json.NewEncoder(rw).Encode(body)
}

func (a *App) discoverableUserHandler(rawID, userHandle []byte) (user webauthn.User, err error) {
	var u userInfo
	var found bool
	a.usersMu.Lock()
loop:
	for _, user := range a.users {
		for _, cred := range user.creds {
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
	a.usersMu.Unlock()

	if !found {
		return nil, errors.New("handle not found")
	}
	return u, nil
}

func (a *App) registerStart(rw http.ResponseWriter, r *http.Request) {
	create, err := func() (*protocol.CredentialCreation, error) {
		ctx := r.Context()
		info := ctx.Value(TokenInfoContextKey).(TokenInfo)

		if info.UserID == 0 {
			adminToken := r.FormValue("adminToken")
			if adminToken == "" {
				return nil, fmt.Errorf("no admin token")
			}
			a.sessionTokenMu.Lock()
			_, ok := a.sessionTokens[adminToken]
			a.sessionTokenMu.Unlock()
			if !ok {
				return nil, fmt.Errorf("invalid admin token")
			}

			username := r.FormValue("username")
			if username == "" {
				return nil, fmt.Errorf("empty username")
			}

			err := func() error {
				a.usersMu.Lock()
				defer a.usersMu.Unlock()

				userID := mathrand.Int64()
				for {
					_, ok := a.users[userID]
					if !ok {
						break
					}
					userID = mathrand.Int64()
				}
				for _, user := range a.users {
					if user.Username == username {
						return fmt.Errorf("username in use")
					}
				}
				a.users[userID] = userInfo{
					UserID:   userID,
					Username: username,
				}

				info.UserID = userID

				return nil
			}()
			if err != nil {
				return nil, err
			}

			a.sessionTokenMu.Lock()
			delete(a.sessionTokens, adminToken)
			a.sessionTokenMu.Unlock()
		}

		a.usersMu.Lock()
		user, ok := a.users[info.UserID]
		a.usersMu.Unlock()
		if !ok {
			return nil, errors.New("user not found")
		}

		create, sess, err := a.webauthn.BeginRegistration(user)
		if err != nil {
			return nil, err
		}

		info.webauthnSess = sess
		a.sessionTokenMu.Lock()
		a.sessionTokens[info.SessionID] = info
		a.sessionTokenMu.Unlock()

		return create, nil
	}()
	rw.Header().Set("content-type", "application/json")
	var body any = create
	if err != nil {
		rw.WriteHeader(http.StatusUnauthorized)
		body = map[string]any{
			"status": "error",
			"error":  err.Error(),
		}
	}

	json.NewEncoder(rw).Encode(body)
}

func (a *App) registerFinish(rw http.ResponseWriter, r *http.Request) {
	err := func() error {
		ctx := r.Context()
		info := ctx.Value(TokenInfoContextKey).(TokenInfo)

		a.usersMu.Lock()
		user, ok := a.users[info.UserID]
		a.usersMu.Unlock()
		if !ok {
			return errors.New("user not found")
		}

		if info.webauthnSess == nil {
			return errors.New("no session started")
		}

		cred, err := a.webauthn.FinishRegistration(user, *info.webauthnSess, r)
		if err != nil {
			return err
		}

		user.creds = append(user.creds, *cred)
		a.usersMu.Lock()
		a.users[user.UserID] = user
		a.usersMu.Unlock()

		return nil
	}()
	rw.Header().Set("content-type", "application/json")
	body := map[string]any{"status": "ok"}
	if err != nil {
		rw.WriteHeader(http.StatusUnauthorized)
		body = map[string]any{
			"status": "error",
			"error":  err.Error(),
		}
	}

	json.NewEncoder(rw).Encode(body)
}

func (a *App) logoutPage(rw http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	info := ctx.Value(TokenInfoContextKey).(TokenInfo)

	a.usersMu.Lock()
	user := a.users[info.UserID]
	a.usersMu.Unlock()

	webstyle.Structured(rw, webstyle.NewOptions("end this session", "logout", []gomponents.Node{
		html.H3(gomponents.Text("Log out?")),
		gomponents.Text("hello " + user.Username),
		html.Form(
			html.Method("post"), html.Action("/logout"),
			html.Input(html.Type("submit"), html.Value("Logout")),
		),
	}))
}

func (a *App) logoutAction(rw http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	info := ctx.Value(TokenInfoContextKey).(TokenInfo)

	a.sessionTokenMu.Lock()
	delete(a.sessionTokens, info.SessionID)
	a.sessionTokenMu.Unlock()

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

func (a *App) RequireAuth(next http.Handler) http.Handler {
	return a.requireAuth(next, false)
}

func (a *App) requireAuth(next http.Handler, allowAnonymous bool) http.Handler {
	return http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
		ctx := r.Context()

		info, ok := a.requestUser(r)
		if !ok {
			http.Redirect(rw, r, "/", http.StatusFound)
			return
		}
		if info.UserID <= 0 && !allowAnonymous {
			http.Redirect(rw, r, "/", http.StatusFound)
			return
		}

		ctx = context.WithValue(ctx, TokenInfoContextKey, info)
		r = r.WithContext(ctx)

		next.ServeHTTP(rw, r)
	})
}

// Debug handlers

func (a *App) adminToken(rw http.ResponseWriter, r *http.Request) {
	rawToken := make([]byte, 16)
	rand.Read(rawToken)
	token := []byte("mooa_")
	token = base32.StdEncoding.AppendEncode(token, rawToken)

	tokenInfo := TokenInfo{
		SessionID: string(token),
		Created:   time.Now(),
		UserID:    -1,
	}

	a.sessionTokenMu.Lock()
	a.sessionTokens[tokenInfo.SessionID] = tokenInfo
	a.sessionTokenMu.Unlock()

	rw.Write(token)
}

func (a *App) requireAdmin(rw http.ResponseWriter, r *http.Request) {}

func Register(a *App, r yrun.HTTPRegistrar) {
	r.Pattern("GET", a.host, "/{$}", http.HandlerFunc(a.homepage))
	r.Pattern("POST", a.host, "/login/start", a.requireAuth(http.HandlerFunc(a.loginStart), true))
	r.Pattern("POST", a.host, "/login/finish", a.requireAuth(http.HandlerFunc(a.loginFinish), true))
	r.Pattern("POST", a.host, "/register/start", a.requireAuth(http.HandlerFunc(a.registerStart), true))
	r.Pattern("POST", a.host, "/register/finish", a.requireAuth(http.HandlerFunc(a.registerFinish), true))
	r.Pattern("POST", a.host, "/update", a.RequireAuth(http.HandlerFunc(a.update)))
	r.Pattern("GET", a.host, "/logout", a.RequireAuth(http.HandlerFunc(a.logoutPage)))
	r.Pattern("POST", a.host, "/logout", a.RequireAuth(http.HandlerFunc(a.logoutAction)))
}

func Admin(a *App, r yrun.HTTPRegistrar) {
	r.Pattern("GET", "", "/auth/admin-token", http.HandlerFunc(a.adminToken))
}
