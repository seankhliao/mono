package githost

import (
	"bytes"
	"crypto/rand"
	"crypto/subtle"
	"encoding/hex"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"log/slog"
	"net/http"
	"net/http/cgi"
	"os"
	"path"
	"path/filepath"
	"slices"
	"strings"
	"sync"

	"go.seankhliao.com/mono/webstyle"
	"golang.org/x/crypto/argon2"
	"maragu.dev/gomponents"
	"maragu.dev/gomponents/html"
)

const (
	cgitrc = `
virtual-root=/
js=/static/cgit/cgit.js
css=/static/cgit/cgit.css
favicon=/static/cgit/favicon.ico
logo=/static/cgitcgit.png
`
)

type GitHost struct {
	Dir  string
	Host string

	configPath string
	users      map[UserID]ConfigUser
	repos      map[RepoID]ConfigRepo
	tokenMu    sync.Mutex
	token      map[AuthToken]UserID

	gitPath    string
	cgitPath   string
	cgitStatic string

	log     *slog.Logger
	cgitLog *log.Logger
}

// Flags implements [run.Simpler].
func (g *GitHost) Flags(fset *flag.FlagSet) error {
	fset.StringVar(&g.Dir, "git.dir", "data/git", "path to store git repos")
	fset.StringVar(&g.Host, "git.host", "git.liao.dev", "hostname to serve on")
	fset.StringVar(&g.configPath, "git.config", "data/githost.json", "path to config file")

	fset.StringVar(&g.gitPath, "git.git", "/usr/bin/git", "path to git binary")
	fset.StringVar(&g.cgitPath, "git.cgit", "/usr/lib/cgit/cgit.cgi", "path to cgit binary")
	fset.StringVar(&g.cgitStatic, "git.cgit-static", "/usr/share/webapps/cgit", "path to cgit static resources")

	return nil
}

func (g *GitHost) Register(mux *http.ServeMux, logh slog.Handler) error {
	mux.Handle(fmt.Sprintf("GET %s /static/cgit/", g.Host), http.StripPrefix("/static/cgit", http.FileServer(http.Dir(g.cgitStatic))))

	mux.HandleFunc(fmt.Sprintf("GET %s /", g.Host), g.handleCgit)

	mux.HandleFunc(fmt.Sprintf("GET %s/{repo}/info/refs", g.Host), g.handleGit)
	mux.HandleFunc(fmt.Sprintf("POST %s/{repo}/git-upload-pack", g.Host), g.handleGit)
	mux.HandleFunc(fmt.Sprintf("POST %s/{repo}/git-receive-pack", g.Host), g.handleGit)

	mux.HandleFunc(fmt.Sprintf("GET %s/login", g.Host), g.loginPage)
	mux.HandleFunc(fmt.Sprintf("POST %s/login", g.Host), g.loginPost)

	g.log = slog.New(logh)
	g.cgitLog = slog.NewLogLogger(logh, slog.LevelWarn)

	err := g.readConfig()
	if err != nil {
		return fmt.Errorf("prepare config: %w", err)
	}

	return nil
}

func (g *GitHost) handleCgit(rw http.ResponseWriter, r *http.Request) {
	userID := g.authState(r)
	cgitrcPath := g.users[userID].cgitrcPath

	c := &cgi.Handler{
		Path: g.cgitPath,
		Dir:  g.Dir,
		Env: []string{
			"CGIT_CONFIG=" + cgitrcPath,
		},
		Logger: g.cgitLog,
	}
	c.ServeHTTP(rw, r)
}

func (g *GitHost) handleGit(rw http.ResponseWriter, r *http.Request) {
	const recv string = "git-receive-pack"

	repoID := RepoID(r.PathValue("repo"))
	userID := g.authState(r)

	allowed := g.allowRead(repoID, userID)
	if path.Base(r.URL.Path) == recv || slices.Contains(r.URL.Query()["service"], recv) {
		allowed = g.allowWrite(repoID, userID)
	}

	if !allowed {
		if userID != UserAnonymous {
			http.Error(rw, "permission denied", http.StatusForbidden)
			return
		}
		rw.Header().Set("www-authenticate", "Bearer")
		http.Error(rw, "requires auth", http.StatusUnauthorized)
		return
	}

	c := &cgi.Handler{
		Path: g.gitPath,
		Dir:  g.Dir,
		Env: []string{
			"GIT_PROJECT_ROOT=" + g.Dir,
		},
		Args:   []string{"http-backend"},
		Logger: g.cgitLog,
	}
	c.ServeHTTP(rw, r)
}

func (g *GitHost) readConfig() error {
	b, err := os.ReadFile(g.configPath)
	if err != nil {
		return fmt.Errorf("read config file %s: %w", g.configPath, err)
	}
	var config Config
	err = json.Unmarshal(b, &config)
	if err != nil {
		return fmt.Errorf("unmarshal config file: %s: %w", g.configPath, err)
	}
	tmpDir, err := os.MkdirTemp(os.TempDir(), "githost.cgitrc")
	if err != nil {
		return fmt.Errorf("prepare temp dir: %w", err)
	}

	g.users = make(map[UserID]ConfigUser)
	for _, user := range config.Users {
		buf := bytes.NewBufferString(cgitrc)
		for _, repo := range config.Repos {
			if slices.Contains(repo.Write, user.ID) || slices.Contains(repo.Read, user.ID) {
				buf.WriteString("\nrepo.url=")
				buf.WriteString(string(repo.ID))
				buf.WriteString("\nrepo.path=")
				buf.WriteString(filepath.Join(g.Dir, string(repo.ID)))
				buf.WriteString("\n")

			}
		}
		f, err := os.CreateTemp(tmpDir, "cgitrc")
		if err != nil {
			return fmt.Errorf("create gitrc file for %s: %w", user.ID, err)
		}
		user.cgitrcPath = filepath.Join(tmpDir, f.Name())
		_, err = buf.WriteTo(f)
		if err != nil {
			return fmt.Errorf("write gitrc file for %s: %w", user.ID, err)
		}
		f.Close()

		g.users[user.ID] = user
	}
	g.repos = make(map[RepoID]ConfigRepo)
	for _, repo := range config.Repos {
		g.repos[repo.ID] = repo
	}

	g.token = make(map[AuthToken]UserID)

	return nil
}

func (g *GitHost) allowRead(repo RepoID, user UserID) bool {
	return slices.Contains(g.repos[repo].Read, user)
}

func (g *GitHost) allowWrite(repo RepoID, user UserID) bool {
	return slices.Contains(g.repos[repo].Write, user)
}

const (
	cookieName   = "githost_login"
	cookiePrefix = "githost_"
)

func (g *GitHost) authState(r *http.Request) UserID {
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

	g.tokenMu.Lock()
	defer g.tokenMu.Unlock()
	u, ok := g.token[token]
	if ok {
		userID = u
	}
	return userID
}

func (g *GitHost) loginPage(rw http.ResponseWriter, r *http.Request) {
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

func (g *GitHost) loginPost(rw http.ResponseWriter, r *http.Request) {
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

	want, err := hex.DecodeString(g.users[userID].Argon2ID)
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
		g.tokenMu.Lock()
		defer g.tokenMu.Unlock()
		g.token[token] = userID
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
