// yhttp provides extra http helpers for [net/http].
package yhttp

import (
	"bytes"
	"fmt"
	"net/http"
	"net/url"
	"slices"
	"strings"
	"sync"
	"time"

	"maragu.dev/gomponents"
	"maragu.dev/gomponents/html"
)

type (
	// Interceptor represents generic http middleware.
	// it should return a function that calls "next" after it has done its modifications.
	Interceptor = func(next http.Handler) http.Handler
	// Handler is a type alias to the underlying signature of a [net/http.ServeHTTP].
	// It's for convenience of passing around the function/method directly.
	Handler = func(rw http.ResponseWriter, r *http.Request)
)

// Chain chains together [Interceptor]s before calling "base".
// The first interceptor is the outermost
func Chain(base Handler, interceptors ...Interceptor) http.Handler {
	var h http.Handler = http.HandlerFunc(base)
	slices.Reverse(interceptors)
	for _, in := range interceptors {
		h = in(h)
	}
	return h
}

// Registrar represents a mux that can register handlers on different paths.
type Registrar interface {
	// Handle passes through to the underlying [net/http.ServeMux]
	Handle(string, http.Handler)
	// Pattern allows passing the method and host separately, as well as passing [Interceptor]s
	Pattern(method, host, pattern string, handler Handler, interceptors ...Interceptor)
	// [net/http.Handler]
	ServeHTTP(http.ResponseWriter, *http.Request)
}

var (
	_ Registrar    = New()
	_ http.Handler = New()
)

// New returns a basic mux.
func New() Registrar {
	return &mux{
		mux:   http.NewServeMux(),
		hosts: make(map[string]struct{}),
	}
}

// Debug returns a mux that registers an index page on "/"
// to registered paths.
func Debug() Registrar {
	m := New().(*mux)
	m.debug = true
	return m
}

type mux struct {
	mux   *http.ServeMux
	hosts map[string]struct{}

	debug bool
	links []string
	once  sync.Once
}

func (m *mux) Pattern(method, host, pattern string, handler Handler, interceptors ...Interceptor) {
	var pat strings.Builder
	if method != "" {
		pat.WriteString(method)
		pat.WriteString(" ")
	}
	pat.WriteString(host)
	if m.hosts == nil {
		m.hosts = make(map[string]struct{})
	}
	m.hosts[host] = struct{}{}
	pat.WriteString(pattern)
	m.mux.Handle(pat.String(), Chain(handler, interceptors...))

	if m.debug {
		if !strings.Contains(pattern, "{") {
			m.links = append(m.links, pattern)
		}
	}
}

func (m *mux) Handle(s string, h http.Handler) {
	m.mux.Handle(s, h)
}

func (m *mux) ServeHTTP(rw http.ResponseWriter, r *http.Request) {
	m.once.Do(func() {
		if !m.debug {
			return
		}
		var links []gomponents.Node
		for _, link := range m.links {
			links = append(links, html.Li(html.A(html.Href(link), gomponents.Text(link))))
		}
		buf := new(bytes.Buffer)
		html.Doctype(
			html.HTML(
				html.Lang("en"),
				html.Head(
					html.Meta(html.Charset("utf-8")),
					html.Meta(html.Name("viewport"), html.Content("width=device-width,minimum-scale=1,initial-scale=1")),
					html.TitleEl(gomponents.Text("Debug Endpoints")),
				),
				html.Body(
					html.H1(gomponents.Text("Debug Endpoints")),
					html.Ul(links...),
				),
			),
		).Render(buf)
		index := buf.Bytes()
		t := time.Now()
		m.Pattern("GET", "", "/{$}", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if strings.Contains(r.Header.Get("accept"), "text/html") {
				http.ServeContent(w, r, "index.html", t, bytes.NewReader(index))
				return
			}
			for _, link := range m.links {
				u := &url.URL{}
				u.Scheme = "http"
				u.Host = r.Host
				u.Path = link
				fmt.Fprintf(w, "%s\n", u.String())
			}
		}))
	})

	m.mux.ServeHTTP(rw, r)
}
