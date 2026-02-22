package main

import (
	"bytes"
	"context"
	"crypto/rand"
	"crypto/subtle"
	_ "embed"
	"encoding/hex"
	"fmt"
	"log/slog"
	"net/http"
	"net/http/cgi"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"slices"
	"strings"
	"sync"

	"go.seankhliao.com/mono/cueconf"
	"go.seankhliao.com/mono/webstyle"
	"go.seankhliao.com/mono/webstyle/webstatic"
	"go.seankhliao.com/mono/yhttp"
	"go.seankhliao.com/mono/yo11y"
	"go.seankhliao.com/mono/yrun"
	"golang.org/x/crypto/argon2"
	"maragu.dev/gomponents"
	"maragu.dev/gomponents/html"
)

//go:embed schema.cue
var configSchema string

func Register(a *App, r yhttp.Registrar) {
	webstatic.Register(r)
	r.Handle("GET /static/cgit/", http.StripPrefix("/static/cgit", http.FileServer(http.Dir(cgitDir))))
	r.Pattern("POST", "", "/{repo}/git-upload-pack", a.gitHTTP)
	r.Pattern("POST", "", "/{repo}/git-receive-pack", a.gitHTTP)
	r.Pattern("GET", "", "/{repo}/info/refs", a.gitHTTP)
	r.Pattern("GET", "", "/", a.cgit)
	r.Pattern("GET", "", "/login", a.loginPage)
	r.Pattern("POST", "", "/login", a.loginPost)
}

type (
	UserID    string
	RepoID    string
	ActionID  string
	AuthToken string
)

const (
	ActionRead  ActionID = "read"
	ActionWrite ActionID = "write"
)

const (
	UserAnonymous UserID = "anonymous"
)

const (
	cookieName   = "githost_login"
	cookiePrefix = "githost_"
)

const (
	cgitDir = "/usr/share/webapps/cgit" // alpine
	cgitrc  = "virtual-root=/\n" +
		"js=/static/cgit/cgit.js\n" +
		"css=/static/cgit/cgit.css\n" +
		"favicon=/static/cgit/favicon.ico\n" +
		"logo=/static/cgitcgit.png\n"
)

type Config struct {
	ConfigFile string `env:"APP_CONFIG_PATH"`

	Dir   string
	Repos map[RepoID]RepoConfig
	Users map[UserID]UserConfig
}

type RepoConfig struct {
	ID      string
	Name    string
	Actions map[ActionID][]UserID
}
type UserConfig struct {
	ID       string
	Name     string
	Argon2ID string

	cgitrcPath string
}

type App struct {
	config Config

	tokenMu sync.Mutex
	token   map[AuthToken]UserID

	gitPath  string
	cgitPath string

	o11y yo11y.O11y
}

func New(ctx context.Context, ec Config, o yo11y.O11y) (*App, error) {
	c, err := cueconf.ForFile[Config](configSchema, "#GithostConfig", ec.ConfigFile, false)
	if err != nil {
		return nil, fmt.Errorf("decode config: %w", err)
	}

	cgitrcBase, err := os.MkdirTemp(os.TempDir(), "cgitrc.*")
	if err != nil {
		return nil, fmt.Errorf("create dir for cgitrcs: %w", err)
	}
	for userID, conf := range c.Users {
		cgitrc := cgitrcForUser(cgitrc, userID, c.Repos)
		p := filepath.Join(cgitrcBase, "cgitrc."+string(userID))
		err = os.WriteFile(p, cgitrc, 0o644)
		if err != nil {
			return nil, fmt.Errorf("write cgitrc for %v: %w", userID, err)
		}

		conf.cgitrcPath = p
		c.Users[userID] = conf
	}

	gitPath, err := exec.LookPath("git")
	if err != nil {
		return nil, fmt.Errorf("can't find git: %w", err)
	}
	cgitPath := "/usr/share/webapps/cgit/cgit"

	os.Chdir(c.Dir)

	return &App{
		config: c,
		token:  make(map[AuthToken]UserID),

		gitPath:  gitPath,
		cgitPath: cgitPath,

		o11y: o.Sub("githost"),
	}, nil
}

func main() {
	os.Exit(yrun.Run(yrun.Config[Config, App]{
		Config: Config{},
		New:    New,
		HTTP:   Register,
	}))
}

const recv string = "git-receive-pack"

func (a *App) gitHTTP(rw http.ResponseWriter, r *http.Request) {
	repoID := RepoID(r.PathValue("repo"))
	userID := a.authState(r)

	action := ActionWrite
	if path.Base(r.URL.Path) != recv && !slices.Contains(r.URL.Query()["service"], recv) {
		action = ActionRead
	}

	if !a.allowedAction(repoID, userID, action) {
		if userID != UserAnonymous {
			a.o11y.L.Info("permission denied", "repo", repoID, "user", userID, "action", action)
			http.Error(rw, "permission denied", http.StatusForbidden)
			return
		}
		rw.Header().Set("www-authenticate", "Bearer")
		http.Error(rw, "requires auth", http.StatusUnauthorized)
		return
	}

	c := &cgi.Handler{
		Path: a.gitPath,
		Dir:  a.config.Dir,
		Env: []string{
			"GIT_PROJECT_ROOT=" + a.config.Dir,
		},
		Args:   []string{"http-backend"},
		Logger: slog.NewLogLogger(a.o11y.H, slog.LevelWarn),
	}
	c.ServeHTTP(rw, r)
}

func (a *App) allowedAction(repo RepoID, user UserID, action ActionID) bool {
	return slices.Contains(a.config.Repos[repo].Actions[action], user)
}

func (a *App) authState(r *http.Request) UserID {
	userID := UserAnonymous

	var token AuthToken
	_, pass, _ := r.BasicAuth()
	if strings.HasPrefix(cookiePrefix, pass) {
		token = AuthToken(pass)
	}

	if token == "" {
		cookie, err := r.Cookie(cookieName)
		if err != nil {
			return userID
		}
		if !strings.HasPrefix(cookie.Value, cookiePrefix) {
			return userID
		}
		token = AuthToken(cookie.Value)
	}

	a.tokenMu.Lock()
	defer a.tokenMu.Unlock()
	u, ok := a.token[token]
	if ok {
		userID = u
	}
	return userID
}

func (a *App) cgit(rw http.ResponseWriter, r *http.Request) {
	userID := a.authState(r)
	cgitrcPath := a.config.Users[userID].cgitrcPath

	c := &cgi.Handler{
		Path: a.cgitPath,
		Dir:  a.config.Dir,
		Env: []string{
			"CGIT_CONFIG=" + cgitrcPath,
		},
		Logger: slog.NewLogLogger(a.o11y.H, slog.LevelWarn),
	}
	c.ServeHTTP(rw, r)
}

func cgitrcForUser(cgitrc string, userID UserID, repos map[RepoID]RepoConfig) []byte {
	buf := bytes.NewBufferString(cgitrc)
	for _, repoConfig := range repos {
		switch {
		case slices.Contains(repoConfig.Actions[ActionWrite], userID):
			fallthrough
		case slices.Contains(repoConfig.Actions[ActionRead], userID):
			buf.WriteString("\nrepo.url=")
			buf.WriteString(repoConfig.ID)
			buf.WriteString("\nrepo.path=")
			buf.WriteString(repoConfig.ID)
			buf.WriteString("\n")
		}
	}
	return buf.Bytes()
}

func (a *App) loginPage(rw http.ResponseWriter, r *http.Request) {
	nodes := []gomponents.Node{
		html.H3(gomponents.Text("log in")),
		html.Form(
			html.Action("/login"), html.Method("post"),
			html.Label(html.For("user_id"), gomponents.Text("email")),
			html.Input(html.Type("email"), html.ID("user_id"), html.Name("user_id"), html.Placeholder("me@example.com")),
			html.Label(html.For("password"), gomponents.Text("password")),
			html.Input(html.Type("password"), html.ID("password"), html.Name("password")),
			html.Input(html.Type("submit"), html.ID("submit"), html.Name("log in")),
		),
	}
	webstyle.Structured(rw, webstyle.NewOptions("login", "log in to git", nodes))
}

func (a *App) loginPost(rw http.ResponseWriter, r *http.Request) {
	err := r.ParseForm()
	if err != nil {
		http.Error(rw, "invalid form", http.StatusBadRequest)
		return
	}

	user := r.FormValue("user_id")
	password := r.FormValue("password")
	if user == "" || password == "" {
		http.Error(rw, "invalid form", http.StatusBadRequest)
		return
	}

	userID := UserID(user)

	got := argon2.IDKey([]byte(password), []byte(userID), 1, 64*1024, 4, 32)

	want, err := hex.DecodeString(a.config.Users[userID].Argon2ID)
	if err != nil {
		http.Error(rw, "invalid credentials", http.StatusForbidden)
		return
	}
	if subtle.ConstantTimeCompare(got, []byte(want)) != 1 {
		http.Error(rw, "invalid credentials", http.StatusForbidden)
		return
	}

	token := AuthToken(cookiePrefix + rand.Text())

	func() {
		a.tokenMu.Lock()
		defer a.tokenMu.Unlock()
		a.token[token] = userID
	}()

	http.SetCookie(rw, &http.Cookie{
		Domain:   r.Host,
		Path:     "/",
		HttpOnly: true,
		Secure:   true,
		Name:     cookieName,
		Value:    string(token),
	})
	http.Redirect(rw, r, "/", http.StatusFound)
}
