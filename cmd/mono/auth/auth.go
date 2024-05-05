package auth

import (
	"context"
	"crypto/rand"
	_ "embed"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"strings"

	"github.com/go-webauthn/webauthn/protocol"
	"github.com/go-webauthn/webauthn/webauthn"
	"github.com/maragudk/gomponents"
	"github.com/maragudk/gomponents/html"
	"go.etcd.io/bbolt"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/trace"
	"go.seankhliao.com/mono/httpjson"
	"go.seankhliao.com/mono/spanerr"
	"go.seankhliao.com/mono/webstyle"
)

const CookieName = "mono_session"

var (
	BucketSession = []byte(`auth_sessions`)
	BucketUser    = []byte(`auth_users`)
	BucketSystem  = []byte(`auth_system`)
	BucketCreds   = []byte(`auth_creds`)
)

type authContextKey struct{}

var AuthInfo authContextKey

type Config struct {
	ID       string
	Origins  []string
	AdminKey string

	DB *bbolt.DB
}

type Handlers struct {
	Index          http.Handler
	LoginStart     http.Handler
	LoginEnd       http.Handler
	RegisterStart  http.Handler
	RegisterEnd    http.Handler
	RegisterRemove http.Handler
	Logout         http.Handler
	Check          func(http.Handler) http.Handler
}

func New(c Config) (Handlers, error) {
	tr := otel.Tracer("auth")

	requireResidentKey := true
	wan, err := webauthn.New(&webauthn.Config{
		RPID:                  c.ID,
		RPDisplayName:         c.ID,
		RPOrigins:             c.Origins,
		Debug:                 true,
		AttestationPreference: protocol.PreferDirectAttestation,
		AuthenticatorSelection: protocol.AuthenticatorSelection{
			RequireResidentKey: &requireResidentKey,
			ResidentKey:        protocol.ResidentKeyRequirementRequired,
		},
	})
	if err != nil {
		return Handlers{}, fmt.Errorf("create webauthn: %w", err)
	}

	err = c.DB.Update(func(tx *bbolt.Tx) error {
		for _, bkt := range [][]byte{BucketSession, BucketUser, BucketSystem, BucketCreds} {
			_, err := tx.CreateBucketIfNotExists(bkt)
			if err != nil {
				return fmt.Errorf("create bucket %s: %w", string(bkt), err)
			}
		}
		return nil
	})
	if err != nil {
		return Handlers{}, fmt.Errorf("ensure buckets exist: %w", err)
	}

	return Handlers{
		Index:          handleIndex(c.DB, tr),
		LoginStart:     handleLoginStart(c.DB, wan, tr),
		LoginEnd:       handleLoginEnd(c.DB, wan, tr),
		RegisterStart:  handleRegisterStart(c.DB, wan, tr),
		RegisterEnd:    handleRegisterEnd(c.DB, wan, tr),
		RegisterRemove: handleRegisterRemove(c.DB, tr),
		Logout:         handleLogout(c.DB, tr),
		Check:          checkAuth(c.DB, tr),
	}, nil
}

//go:embed script.js
var scriptJS string

func handleIndex(db *bbolt.DB, tr trace.Tracer) http.Handler {
	return http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
		ctx, span := tr.Start(r.Context(), "handle index page")
		defer span.End()

		content := []gomponents.Node{
			html.H3(html.Em(gomponents.Text("auth ")), gomponents.Text("svr")),
		}

		id := getIdentity(ctx, db, tr, r)
		if id.ID == 0 {
			// not logged in
			content = append(content,
				html.H4(html.Em(gomponents.Text("login"))),
				html.P(gomponents.Text("Log in with a passkey:")),
				html.FormEl(
					html.Action("javascript:loginUser()"),
					html.Input(html.Type("submit"), html.Value("login")),
				),
				html.Script(gomponents.Raw(scriptJS)),
			)
			return
		} else {
			knownCreds := []gomponents.Node{}
			for _, cred := range id.Creds {
				knownCreds = append(knownCreds, html.Tr(
					html.Td(gomponents.Text(hex.EncodeToString(cred.ID))),
					html.Td(gomponents.Text(cred.AttestationType)),
					html.Td(gomponents.Text(string(cred.Authenticator.Attachment))),
					html.Td(gomponents.Text(strconv.FormatUint(uint64(cred.Authenticator.SignCount), 10))),
					html.Td(gomponents.Text(fmt.Sprint(cred.Transport))),
				))
			}
			content = append(content,
				html.H4(html.Em(gomponents.Text("user ")), gomponents.Text(id.Email)),
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
				// html.P(
				// 	html.Strong(gomponents.Text("session start:")),
				// 	gomponents.Text(sess.StartTime.Format(time.DateTime)),
				// ),
				// html.P(
				// 	html.Strong(gomponents.Text("user agent:")),
				// 	gomponents.Text(sess.UserAgent),
				// ),
				// html.P(
				// 	html.Strong(gomponents.Text("login cred:")),
				// 	gomponents.Text(sess.LoginCredID),
				// ),
				html.FormEl(
					html.Action("/logout"), html.Method("post"),
					html.Input(html.Type("submit"), html.Value("logout")),
				),
				html.Script(gomponents.Raw(scriptJS)),
			)
		}

		// logged int

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

func checkAuth(db *bbolt.DB, tr trace.Tracer) func(http.Handler) http.Handler {
	return func(h http.Handler) http.Handler {
		return http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
			ctx, span := tr.Start(r.Context(), "check identity")
			defer span.End()

			id := getIdentity(db, r)
			if id.ID == 0 {
				http.Redirect(rw, r, "/auth/", http.StatusSeeOther)
				return
			}

			h.ServeHTTP(rw, r.WithContext(context.WithValue(ctx, AuthInfo, id)))
		})
	}
}

func handleLoginStart(db *bbolt.DB, wan *webauthn.WebAuthn, tr trace.Tracer) http.Handler {
	return http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
		ctx, span := tr.Start(r.Context(), "start login")
		defer span.End()

		data, wanSess, err := wan.BeginDiscoverableLogin()
		if err != nil {
			spanerr.Err(span, "begin discoverable login", err)
			http.Error(rw, "internal error", http.StatusInternalServerError)
			return
		}

		// TODO set session token
		// TODO store wanSess

		json.Marshal(data)
	})
}

func handleLoginEnd(db *bbolt.DB, wan *webauthn.WebAuthn, tr trace.Tracer) http.Handler {
	return http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
		ctx, span := tr.Start(r.Context(), "end login")
		defer span.End()

		// TODO read session token
		// TODO get wanSess

		cred, err := wan.FinishDiscoverableLogin(handler, wanSess, r)
		if err != nil {
			httpjson.Err(rw, http.StatusBadRequest, "webauthn finish login", err)
			spanerr.Err(span, "webauthn finish login", err)
			return
		}

		if cred.Authenticator.CloneWarning {
			httpjson.Err(rw, http.StatusBadRequest, "cloned authenticator", err)
			spanerr.Err(span, "cloned authenticator", err)
			return
		}

		// TODO update session token

		// TODO redirect?
	})
}

func handleRegisterStart(db *bbolt.DB, wan *webauthn.WebAuthn, tr trace.Tracer) http.Handler {
	return http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
		ctx, span := tr.Start(r.Context(), "start registration")
		defer span.End()

		// TODO get user already registered creds

		var exlcusions []protocol.CredentialDescriptor
		for _, cred := range user.Creds {
			exlcusions = append(exlcusions, cred.Descriptor())
		}

		data, wanSess, err := a.wan.BeginRegistration(user, webauthn.WithExclusions(exlcusions))
		if err != nil {
			httpjson.Err(rw, http.StatusInternalServerError, "webauthn begin registration", err)
			spanerr.Err(span, "webauthn begin registration", err)
			return
		}

		// TODO store wanSess

		b, err := json.Marshal(data)

		rw.Write(b)
	})
}

func handleRegisterEnd(db *bbolt.DB, wan *webauthn.WebAuthn, tr trace.Tracer) http.Handler {
	return http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
		// TODO get session key
		// TODO get wanSess

		cred, err := wan.FinishRegistration(user, wanSess, r)

		// TODO store updated cred
		// TODO ok response
	})
}

func handleLogout(db *bbolt.DB, tr trace.Tracer) http.Handler {
	return http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
		ctx, span := tr.Start(r.Context(), "user logout")
		defer span.End()

		id := getIdentity(ctx, db, tr, r)
		if id.ID != 0 {
			// not logged in
			http.Redirect(rw, r, "/auth/", http.StatusFound)
			return
		}

		// remove session
		err := db.Update(func(tx *bbolt.Tx) error {
			bkt := tx.Bucket(BucketSession)
			return bkt.Delete(id.CurrentToken)
		})
		if err != nil {
			spanerr.Err(span, "remove user session", err,
				attribute.Int64("user.id", id.ID),
			)
			http.Error(rw, "failed to remove user session", http.StatusInternalServerError)
			return
		}

		// TODO: clear cookie

		http.Redirect(rw, r, "/auth/", http.StatusSeeOther)
	})
}

// getIdentity checks a http.Request for any active session tokens.
// It looks for:
//   - header: Authorization: Bearer $token
//   - cookie: mono_session:
func getIdentity(ctx context.Context, db *bbolt.DB, tr trace.Tracer, r *http.Request) Identity {
	ctx, span := tr.Start(ctx, "get identity from http request")
	defer span.End()

	getters := []func(*http.Request) []byte{
		getAuthHeader,
		getCookie,
	}

	for _, getter := range getters {
		var id Identity
		found := func() bool {
			_, span := tr.Start(ctx, "check token from getter")
			defer span.End()

			token := getter(r)
			if len(token) == 0 {
				return false
			}

			db.View(func(tx *bbolt.Tx) error {
				sessionBkt := tx.Bucket(BucketSession)
				userKey := sessionBkt.Get([]byte(token))
				if len(userKey) == 0 {
					return nil
				}
				userBkt := tx.Bucket(BucketUser)
				userInfo := userBkt.Get(userKey)
				if len(userInfo) == 0 {
					return nil
				}
				return json.Unmarshal(userInfo, &id)
			})
			if id.ID == 0 {
				return false
			}
			id.CurrentToken = token
			return true
		}()
		if found {
			return id
		}
	}
	return Identity{}
}

func getAuthHeader(r *http.Request) []byte {
	authHeader := r.Header.Get("authorization")
	token, found := strings.CutPrefix(authHeader, "Bearer ")
	if !found {
		return nil
	}
	return []byte(token)
}

func getCookie(r *http.Request) []byte {
	c, err := r.Cookie(CookieName)
	if err != nil {
		return nil
	}
	return []byte(c.Value)
}

func genToken() string {
	token := make([]byte, 16)
	rand.Read(token)
}

var _ webauthn.User = &Identity{}

type Identity struct {
	ID    int64
	Email string
	Creds []webauthn.Credential

	CurrentToken []byte
}

// might fail if len(email) > 64
func (i Identity) WebAuthnID() []byte                         { return []byte(i.Email) }
func (i Identity) WebAuthnName() string                       { return i.Email }
func (i Identity) WebAuthnDisplayName() string                { return i.Email }
func (i Identity) WebAuthnCredentials() []webauthn.Credential { return i.Creds }
func (i Identity) WebAuthnIcon() string                       { return "" }
