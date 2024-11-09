package yrun

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

type HTTPInterceptor = func(next http.Handler) http.Handler

func ChainF(base func(http.ResponseWriter, *http.Request), interceptors ...HTTPInterceptor) http.Handler {
	return Chain(http.HandlerFunc(base), interceptors...)
}

// Chain chains together interceptors (middleware),
// the first interceptor will be the outermost.
func Chain(base http.Handler, interceptors ...HTTPInterceptor) http.Handler {
	slices.Reverse(interceptors)
	for _, in := range interceptors {
		base = in(base)
	}
	return base
}

// HTTPConfig is the config for an http server
type HTTPConfig struct {
	// host:port listening address
	Address string

	K8s struct {
		Enable bool

		GatewayNamespace string
		GatewayName      string
	}
}

func debugMux() (reg HTTPRegistrar, getMux func() *http.ServeMux) {
	register := &debugRegister{
		mux: muxRegister{http.NewServeMux(), make(map[string]struct{})},
	}

	var finalize sync.Once
	getMux = func() *http.ServeMux {
		finalize.Do(func() {
			var links []gomponents.Node
			for _, link := range register.links {
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
			register.Pattern("GET", "", "/{$}", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				if strings.Contains(r.Header.Get("accept"), "text/html") {
					http.ServeContent(w, r, "index.html", t, bytes.NewReader(index))
					return
				}
				for _, link := range register.links {
					u := &url.URL{}
					u.Scheme = "http"
					u.Host = r.Host
					u.Path = link
					fmt.Fprintf(w, "%s\n", u.String())
				}
			}))
		})
		return register.mux.mux
	}

	return register, getMux
}

type HTTPRegistrar interface {
	Handle(string, http.Handler)
	Pattern(method, host, pattern string, handler func(http.ResponseWriter, *http.Request), interceptors ...HTTPInterceptor)
}

type muxRegister struct {
	mux   *http.ServeMux
	hosts map[string]struct{}
}

func (r *muxRegister) Pattern(method, host, pattern string, handler func(http.ResponseWriter, *http.Request), interceptors ...HTTPInterceptor) {
	var pat strings.Builder
	if method != "" {
		pat.WriteString(method)
		pat.WriteString(" ")
	}
	pat.WriteString(host)
	if r.hosts == nil {
		r.hosts = make(map[string]struct{})
	}
	r.hosts[host] = struct{}{}
	pat.WriteString(pattern)
	r.mux.Handle(pat.String(), ChainF(handler, interceptors...))
}

func (r *muxRegister) Handle(s string, h http.Handler) {
	r.mux.Handle(s, h)
}

type debugRegister struct {
	mux   muxRegister
	links []string
}

func (r *debugRegister) Pattern(method, host, pattern string, handler func(http.ResponseWriter, *http.Request), interceptors ...HTTPInterceptor) {
	r.mux.Pattern(method, host, pattern, handler, interceptors...)
	if !strings.Contains(pattern, "{") {
		r.links = append(r.links, pattern)
	}
}

func (r *debugRegister) Handle(s string, h http.Handler) {
	r.mux.Handle(s, h)
}

func ptr[T any](v T) *T {
	return &v
}
