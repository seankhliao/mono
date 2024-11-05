package yrun

import (
	"bytes"
	"fmt"
	"net/http"
	"net/url"
	"strings"
	"sync"
	"time"

	"maragu.dev/gomponents"
	"maragu.dev/gomponents/html"
)

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
	Pattern(method, host, pattern string, handler http.Handler)
}

type muxRegister struct {
	mux   *http.ServeMux
	hosts map[string]struct{}
}

func (r *muxRegister) Pattern(method, host, pattern string, handler http.Handler) {
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
	r.mux.Handle(pat.String(), handler)
}

func (r *muxRegister) Handle(s string, h http.Handler) {
	r.mux.Handle(s, h)
}

type debugRegister struct {
	mux   muxRegister
	links []string
}

func (r *debugRegister) Pattern(method, host, pattern string, handler http.Handler) {
	r.mux.Pattern(method, host, pattern, handler)
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
