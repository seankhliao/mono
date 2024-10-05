package yrun

import (
	"bytes"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/maragudk/gomponents"
	"github.com/maragudk/gomponents/html"
)

// HTTPConfig is the config for an http server
type HTTPConfig struct {
	// host:port listening address
	Address string
}

func debugMux() (reg HTTPRegistrar, getMux func() *http.ServeMux) {
	register := &debugRegister{
		mux: muxRegister{http.NewServeMux()},
	}

	var finalize sync.Once
	getMux = func() *http.ServeMux {
		finalize.Do(func() {
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
						html.Ul(register.links...),
					),
				),
			).Render(buf)
			index := buf.Bytes()
			t := time.Now()
			register.Pattern("GET", "", "/{$}", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				http.ServeContent(w, r, "index.html", t, bytes.NewReader(index))
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
	mux *http.ServeMux
}

func (r *muxRegister) Pattern(method, host, pattern string, handler http.Handler) {
	var pat strings.Builder
	if method != "" {
		pat.WriteString(method)
		pat.WriteString(" ")
	}
	pat.WriteString(host)
	pat.WriteString(pattern)
	r.mux.Handle(pat.String(), handler)
}

func (r *muxRegister) Handle(s string, h http.Handler) {
	r.mux.Handle(s, h)
}

type debugRegister struct {
	mux   muxRegister
	links []gomponents.Node
}

func (r *debugRegister) Pattern(method, host, pattern string, handler http.Handler) {
	r.mux.Pattern(method, host, pattern, handler)
	r.links = append(r.links, html.Li(html.A(html.Href(pattern), gomponents.Text(pattern))))
}

func (r *debugRegister) Handle(s string, h http.Handler) {
	r.mux.Handle(s, h)
}
