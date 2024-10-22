package main

import (
	"bytes"
	"context"
	"crypto/cipher"
	"crypto/rand"
	_ "embed"
	"encoding/hex"
	"encoding/json"
	"flag"
	"fmt"
	"log/slog"
	"net/http"
	"time"

	"github.com/go-webauthn/webauthn/protocol"
	"github.com/go-webauthn/webauthn/webauthn"
	"maragu.dev/gomponents"
	"maragu.dev/gomponents/html"
	"go.etcd.io/bbolt"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.seankhliao.com/mono/framework"
	"go.seankhliao.com/mono/observability"
	"go.seankhliao.com/mono/webstyle"
	"go.seankhliao.com/mono/webstyle/webstatic"
)

func main() {
	var conf Config
	framework.Run(framework.Config{
		RegisterFlags: conf.RegisterFlags,
		Start: func(ctx context.Context, o *observability.O, mux *http.ServeMux) (cleanup func(), err error) {
			app, err := New(ctx, o, conf)
			if err != nil {
				return nil, fmt.Errorf("setup app: %w", err)
			}

			app.Register(mux)
			webstatic.Register(mux)

			return app.close, nil
		},
	})
}

type App struct {
	db   *bbolt.DB
	aead cipher.AEAD // key for secret cookies
	wan  *webauthn.WebAuthn
	o    *observability.O

	adminKey     string
	cookieDomain string
}

func New(ctx context.Context, o *observability.O, c Config) (*App, error) {
	db, err := bbolt.Open(c.dbPath, 0o644, &bbolt.Options{})
	if err != nil {
		return nil, fmt.Errorf("open database: %w", err)
	}
	err = db.Update(func(tx *bbolt.Tx) error {
		for _, bkt := range [][]byte{
			bucketSystem,
			bucketUser,
			bucketSession,
			bucketCred,
		} {
			_, err := tx.CreateBucketIfNotExists(bkt)
			if err != nil {
				return err
			}
		}
		return nil
	})
	if err != nil {
		return nil, fmt.Errorf("failed to ensure buckets: %w", err)
	}

	t := true
	wan, err := webauthn.New(&webauthn.Config{
		RPID:                  c.ID,
		RPDisplayName:         c.ID,
		RPOrigins:             c.Origins,
		Debug:                 true,
		AttestationPreference: protocol.PreferDirectAttestation,
		AuthenticatorSelection: protocol.AuthenticatorSelection{
			RequireResidentKey: &t,
			ResidentKey:        protocol.ResidentKeyRequirementRequired,
		},
	})
	if err != nil {
		return nil, fmt.Errorf("setup webauthn: %w", err)
	}

	akey := make([]byte, 32)
	rand.Read(akey)
	adminKey := hex.EncodeToString(akey)
	o.L.LogAttrs(ctx, slog.LevelInfo, "admin key", slog.String("admin_key", adminKey))

	app := &App{
		db:           db,
		wan:          wan,
		o:            o,
		adminKey:     adminKey,
		cookieDomain: c.CookieDomain,
	}

	err = app.ensureCookieKey(ctx)
	if err != nil {
		return nil, fmt.Errorf("cookie key: %w", err)
	}

	return app, nil
}

func (a *App) Register(mux *http.ServeMux) {
	// user facing
	mux.Handle("GET /{$}", otelhttp.NewHandler(a.index(), "index page"))
	mux.Handle("POST /login/start", otelhttp.NewHandler(a.startLogin(), "login start"))
	mux.Handle("POST /login/finish", otelhttp.NewHandler(a.finishLogin(), "login finish"))
	mux.Handle("/logout", otelhttp.NewHandler(a.logout(), "logout"))
	mux.Handle("/404", otelhttp.NewHandler(a.staticPage("404", notFoundPage), "404"))

	// internal endpoints
	mux.Handle("GET /api/v1/token/{token}", otelhttp.NewHandler(a.apiv1SessionToken(), "check sessiontoken"))
	mux.Handle("GET /api/v1/cred/{credid}/remove", otelhttp.NewHandler(a.removeCred(), "remove cred"))

	// internal admin endpoints
	mux.Handle("POST /register/{email}/start", otelhttp.NewHandler(a.registerStart(), "register start"))
	mux.Handle("POST /register/{email}/finish", otelhttp.NewHandler(a.registerFinish(), "register finish"))
}

func (a *App) staticPage(title string, content []gomponents.Node) http.Handler {
	ts := time.Now()

	var buf bytes.Buffer
	o := webstyle.NewOptions("authsvr", title, content)
	err := webstyle.Structured(&buf, o)
	if err != nil {
		a.o.Err(context.Background(), "prerender page", err, slog.String("page_title", title))
	}

	b := buf.Bytes()
	return http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
		http.ServeContent(rw, r, "index.html", ts, bytes.NewReader(b))
	})
}

func (a *App) jsonOk(ctx context.Context, rw http.ResponseWriter, obj any) {
	b, _ := json.Marshal(obj)
	rw.Header().Set("content-type", "application/json")
	rw.Write(b)
}

func (a *App) jsonErr(ctx context.Context, rw http.ResponseWriter, msg string, err error, code int, obj any) {
	a.o.Err(ctx, msg, err)
	rw.Header().Set("content-type", "application/json")
	rw.WriteHeader(code)
	b, _ := json.Marshal(obj)
	rw.Write(b)
}

func (a *App) close() {
	a.db.Close()
}

type Config struct {
	dbPath       string
	ID           string
	Origins      []string
	CookieDomain string
}

func (c *Config) RegisterFlags(fset *flag.FlagSet) {
	fset.StringVar(&c.dbPath, "db.path", "db.bbolt", "path to database file (bbolt)")
	fset.StringVar(&c.ID, "webauthn.id", "auth.liao.dev", "core origin id")
	fset.StringVar(&c.CookieDomain, "cookie.domain", "liao.dev", "cookie domain")
	fset.Func("webauthn.origin", "allowed origins for webauthn", func(s string) error {
		c.Origins = append(c.Origins, s)
		return nil
	})
}

var notFoundPage = []gomponents.Node{
	html.H3(html.Em(gomponents.Text("Oops")), gomponents.Text("...")),
	html.P(
		gomponents.Text("Return "),
		html.A(html.Href("/"), gomponents.Text("home")),
	),
}
