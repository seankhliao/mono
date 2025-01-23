package main

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"net/http"
	"os"
	"time"

	"go.seankhliao.com/mono/webstyle"
	"go.seankhliao.com/mono/webstyle/webstatic"
	"go.seankhliao.com/mono/yhttp"
	"go.seankhliao.com/mono/yo11y"
	"go.seankhliao.com/mono/yrun"
	"gocloud.dev/blob"
	"maragu.dev/gomponents"
	"maragu.dev/gomponents/html"
)

func Register(a *App, r yhttp.Registrar) {
	webstatic.Register(r)
	r.Pattern("GET", "", "/{$}", a.index)
	r.Pattern("GET", "", "/{repo}/", a.repo)
}

type Config struct {
	Host   string
	Source string
}
type App struct {
	c Config
	o yo11y.O11y

	t0           time.Time
	indexContent []byte
}

func New(ctx context.Context, c Config, _ *blob.Bucket, o yo11y.O11y) (*App, error) {
	index, err := indexPage(c.Host)
	if err != nil {
		return nil, fmt.Errorf("render index template: %w", err)
	}
	return &App{
		c:            c,
		o:            o.Sub("vanity"),
		t0:           time.Now(),
		indexContent: index,
	}, nil
}

func (a *App) index(rw http.ResponseWriter, r *http.Request) {
	http.ServeContent(rw, r, "index.html", a.t0, bytes.NewReader(a.indexContent))
}

func (a *App) repo(rw http.ResponseWriter, r *http.Request) {
	repo := r.PathValue("repo")
	importPage(rw, a.c.Host, a.c.Source, repo)
}

func main() {
	os.Exit(yrun.Run(yrun.Config[Config, App]{
		Config: Config{
			Host:   "go.seankhliao.com",
			Source: "github.com/seankhliao",
		},
		New:  New,
		HTTP: Register,
	}))
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
