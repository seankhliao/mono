package homepage

import (
	"bytes"
	"fmt"
	"net/http"
	"time"

	"go.seankhliao.com/mono/httpencoding"
	"go.seankhliao.com/mono/webstyle"
	"go.seankhliao.com/mono/yhttp"
	"go.seankhliao.com/mono/yo11y"
	"maragu.dev/gomponents"
	"maragu.dev/gomponents/html"
)

func Register(a *App, r yhttp.Registrar) {
	r.Pattern("GET", a.host, "/{$}", a.ServeHTTP, httpencoding.Handler)
}

type Config struct {
	Host string
}

type App struct {
	host string
	t    time.Time
	b    []byte
}

func New(c Config, o yo11y.O11y) (*App, error) {
	ro := webstyle.NewOptions(c.Host, c.Host, []gomponents.Node{
		html.H3(html.Em(gomponents.Text("inter")), gomponents.Text("webs")),
		html.P(
			html.Em(gomponents.Text("Congratulations")),
			gomponents.Text(" You've found a server on the internet."),
		),
	})
	var buf bytes.Buffer
	err := webstyle.Structured(&buf, ro)
	if err != nil {
		return nil, fmt.Errorf("render web page: %w", err)
	}

	return &App{
		host: c.Host,
		t:    time.Now(),
		b:    buf.Bytes(),
	}, nil
}

func (a *App) ServeHTTP(rw http.ResponseWriter, r *http.Request) {
	http.ServeContent(rw, r, "index.html", a.t, bytes.NewReader(a.b))
}
