package main

import (
	"bytes"
	"context"
	"flag"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"time"

	"maragu.dev/gomponents"
	"maragu.dev/gomponents/html"
	"go.seankhliao.com/mono/framework"
	"go.seankhliao.com/mono/observability"
	"go.seankhliao.com/mono/webstyle"
	"go.seankhliao.com/mono/webstyle/webstatic"
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

			index, err := indexPage(host)
			if err != nil {
				return nil, fmt.Errorf("render index template: %w", err)
			}
			t0 := time.Now()

			webstatic.Register(m)
			m.HandleFunc("GET /{$}", func(rw http.ResponseWriter, r *http.Request) {
				ctx, span := o.T.Start(r.Context(), "serve index page")
				defer span.End()

				http.ServeContent(rw, r, "index.html", t0, bytes.NewReader(index))
				o.L.LogAttrs(ctx, slog.LevelInfo, "served index page",
					requestAttrs(r))
			})
			m.HandleFunc("GET /{repo}/", func(rw http.ResponseWriter, r *http.Request) {
				ctx, span := o.T.Start(r.Context(), "serve vanity")
				defer span.End()

				repo := r.PathValue("repo")
				importPage(rw, host, source, repo)
				if err != nil {
					o.HTTPErr(ctx, "write response", err, rw, http.StatusInternalServerError)
					return
				}

				o.L.LogAttrs(ctx, slog.LevelInfo, "served module page",
					slog.String("repo", repo), requestAttrs(r))
			})
			return nil, nil
		},
	})
}

func indexPage(host string) ([]byte, error) {
	buf := new(bytes.Buffer)
	err := webstyle.Structured(buf, webstyle.Options{
		CanonicalURL: "https://" + host,
		CompactStyle: true,
		Minify:       true,
		Title:        "vanity",
		Subtitle:     host,
		Description:  "vanity go import paths for sean",

		Content: []gomponents.Node{
			html.H3(html.Em(gomponents.Text("vanity"))),
			html.P(
				gomponents.Text("This is a custom "),
				html.A(
					html.Href("https://pkg.go.dev/cmd/go#hdr-Remote_import_paths"),
					gomponents.Text("remote import path"),
				),
				gomponents.Text("redirector for Go."),
			),
			html.P(gomponents.Text("All requests are redirected to a github repo matching the first path element.")),
		},
	})
	return buf.Bytes(), err
}

func importPage(w io.Writer, host, gitHost, repo string) error {
	importPath := host + "/" + repo
	hostPath := gitHost + "/" + repo
	return webstyle.Structured(w, webstyle.Options{
		CanonicalURL: "https://" + importPath,
		CompactStyle: true,
		Minify:       true,
		Title:        repo,
		Subtitle:     "module " + importPath,
		Head: []gomponents.Node{
			html.Meta(
				html.Name("go-import"),
				html.Content(importPath+" git "+"https://"+hostPath),
			),
			html.Meta(
				html.Name("go-source"),
				html.Content(
					importPath+"\n"+
						"https://"+hostPath+"\n"+
						"https://"+hostPath+"/tree/main{/dir}\n"+
						"https://"+hostPath+"/blob/main{/dir}/{file}#L{line}",
				),
			),
		},
		Content: []gomponents.Node{
			html.H3(
				gomponents.Text(host+"/"),
				html.Em(gomponents.Text(repo)),
			),
			html.P(
				html.Strong(gomponents.Text("Source: ")),
				html.A(
					html.Href("https://"+hostPath),
					gomponents.Text(hostPath),
				),
			),
			html.P(
				html.Strong(gomponents.Text("Docs: ")),
				html.A(
					html.Href("https://pkg.go.dev/"+importPath),
					gomponents.Text("pkg.go.dev/"+importPath),
				),
			),
		},
	})
}

func requestAttrs(r *http.Request) slog.Attr {
	return slog.Group("http_request",
		slog.String("method", r.Method),
		slog.String("url", r.URL.String()),
		slog.String("proto", r.Proto),
		slog.String("user_agent", r.UserAgent()),
		slog.String("remote_address", r.RemoteAddr),
		slog.String("referrer", r.Referer()),
		slog.String("x-forwarded-for", r.Header.Get("x-forwarded-for")),
		slog.String("forwarded", r.Header.Get("forwarded")),
	)
}
