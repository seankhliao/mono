package main

import (
	"bytes"
	"context"
	_ "embed"
	"errors"
	"flag"
	"fmt"
	"html/template"
	"io"
	"log/slog"
	"net/http"
	"strings"
	"time"

	"go.seankhliao.com/mono/framework"
	"go.seankhliao.com/mono/observability"
	"go.seankhliao.com/mono/webstyle"
	"go.seankhliao.com/mono/webstyle/webstatic"
)

var (
	//go:embed index.md
	indexRaw []byte

	//go:embed repo.md.gotmpl
	repoRaw string
	repoTpl = template.Must(template.New("").Parse(repoRaw))

	headRaw = `
    <meta
      name="go-import"
      content="go.seankhliao.com/{{ .Repo }} git https://{{ .Source }}/{{ .Repo }}">
    <meta
      name="go-source"
      content="{{ .Host }}/{{ .Repo }}
        https://{{ .Source }}/{{ .Repo }}
        https://{{ .Source }}/{{ .Repo }}/tree/main{/dir}
        https://{{ .Source }}/{{ .Repo }}/blob/main{/dir}/{file}#L{line}">
`
	headTpl = template.Must(template.New("").Parse(headRaw))
)

func main() {
	var host, source string
	framework.Run(framework.Config{
		RegisterFlags: func(fset *flag.FlagSet) {
			fset.StringVar(&host, "vanity.host", "go.seankhliao.com", "host this server runs on")
			fset.StringVar(&source, "vanity.source", "github.com/seankhliao", "where the code is hosted")
		},
		Start: func(ctx context.Context, o *observability.O, m *http.ServeMux) (func(), error) {
			o = o.Component("vanity")

			render := webstyle.NewRenderer(webstyle.TemplateCompact)
			index, err := render.RenderBytes(indexRaw, webstyle.Data{})
			if err != nil {
				return nil, fmt.Errorf("render index template: %w", err)
			}
			t0 := time.Now()

			webstatic.Register(m)
			m.HandleFunc("/", func(rw http.ResponseWriter, r *http.Request) {
				ctx, span := o.T.Start(r.Context(), "serve vanity")
				defer span.End()

				slogHTTPRequest := slog.Group("http_request",
					slog.String("method", r.Method),
					slog.String("url", r.URL.String()),
					slog.String("proto", r.Proto),
					slog.String("user_agent", r.UserAgent()),
					slog.String("remote_address", r.RemoteAddr),
					slog.String("referrer", r.Referer()),
					slog.String("x-forwarded-for", r.Header.Get("x-forwarded-for")),
					slog.String("forwarded", r.Header.Get("forwarded")),
				)

				if r.Method != http.MethodGet {
					o.HTTPErr(ctx, "GET only", errors.New("method not allowed"), rw, http.StatusMethodNotAllowed, slogHTTPRequest)
					return
				}

				p := strings.TrimPrefix(r.URL.Path, "/")
				if p == "" { // index
					http.ServeContent(rw, r, "index.html", t0, bytes.NewReader(index))
					o.L.LogAttrs(ctx, slog.LevelInfo, "served index page",
						slogHTTPRequest,
					)
					return
				}

				// other pages
				repo, _, _ := strings.Cut(p, "/")
				data := map[string]string{"Repo": repo, "Source": source, "Host": host}

				var buf1 bytes.Buffer
				err := repoTpl.Execute(&buf1, data)
				if err != nil {
					o.HTTPErr(ctx, "render repo", err, rw, http.StatusInternalServerError)
					return
				}
				var buf2 bytes.Buffer
				err = headTpl.Execute(&buf2, data)
				if err != nil {
					o.HTTPErr(ctx, "render head", err, rw, http.StatusInternalServerError)
					return
				}

				var buf3 bytes.Buffer
				err = render.Render(&buf3, &buf1, webstyle.Data{
					Head: buf2.String(),
				})
				if err != nil {
					o.HTTPErr(ctx, "render html", err, rw, http.StatusInternalServerError)
					return
				}
				_, err = io.Copy(rw, &buf3)
				if err != nil {
					o.HTTPErr(ctx, "write response", err, rw, http.StatusInternalServerError)
					return
				}

				o.L.LogAttrs(ctx, slog.LevelInfo, "served module page", slog.String("repo", repo), slogHTTPRequest)
			})
			return nil, nil
		},
	})
}
