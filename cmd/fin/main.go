package main

import (
	"bytes"
	"context"
	"errors"
	"flag"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strings"

	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.seankhliao.com/mono/cmd/fin/findata"
	"go.seankhliao.com/mono/framework"
	"go.seankhliao.com/mono/httpencoding"
	"go.seankhliao.com/mono/observability"
	"go.seankhliao.com/mono/webstyle"
)

func main() {
	conf := &Config{}
	framework.Run(framework.Config{
		RegisterFlags: conf.SetFlags,
		Start: func(ctx context.Context, o *observability.O, m *http.ServeMux) (func(), error) {
			switch conf.mode {
			case "view":
				err := View(ctx, o, conf)
				if err != nil {
					o.Err(ctx, "view", err)
					os.Exit(1)
				}
				os.Exit(0)
			case "submit":
				err := Submit(ctx, o, conf)
				if err != nil {
					o.Err(ctx, "submit", err)
					os.Exit(1)
				}
				os.Exit(0)
			case "serve":
				app := New(ctx, o, conf)
				app.Register(m)
				return nil, nil
			}
			return nil, fmt.Errorf("unknown mode: %q", conf.mode)
		},
	})
}

type Config struct {
	mode string

	files         [][]byte
	submitAddress *url.URL
	view          findata.View

	dir string
}

func (c *Config) SetFlags(fset *flag.FlagSet) {
	fset.StringVar(&c.mode, "mode", "serve", "view|submit|serve")

	fset.Func("file", "files to view/submit", func(s string) error {
		b, err := os.ReadFile(s)
		if err != nil {
			return err
		}
		c.files = append(c.files, b)
		return nil
	})
	c.submitAddress, _ = url.Parse("http://fin-ihwa.badger-altered.ts.net/")
	fset.Func("submit.addr", "http://fin-ihwa.badger-altered.ts.net/", func(s string) error {
		u, err := url.Parse(s)
		if err != nil {
			return err
		}
		c.submitAddress = u
		return nil
	})
	fset.Func("view", "holdings|incomes|expenses", func(s string) error {
		switch s {
		case "holdings":
			c.view = findata.ViewHoldings
		case "incomes":
			c.view = findata.ViewIncomes
		case "expenses":
			c.view = findata.ViewExpenses
		default:
			return errors.New("unknown view")
		}
		return nil
	})

	fset.StringVar(&c.dir, "data.dir", "", "data storage dir")
}

func Submit(ctx context.Context, o *observability.O, conf *Config) error {
	client := &http.Client{Transport: otelhttp.NewTransport(http.DefaultTransport)}
	for _, b := range conf.files {
		cur, err := findata.DecodeOne(b)
		if err != nil {
			return o.Err(ctx, "parse file", err)
		}
		uc := conf.submitAddress
		addr := uc.JoinPath(cur.Currency).String()
		res, err := client.Post(addr, "application/cue", bytes.NewReader(b))
		if err != nil {
			return o.Err(ctx, "post file", err, slog.String("addr", addr))
		} else if res.StatusCode != http.StatusOK {
			return o.Err(ctx, "post file response", errors.New(res.Status))
		}
		o.L.LogAttrs(ctx, slog.LevelInfo, "submitted file")
	}
	return nil
}

func View(ctx context.Context, o *observability.O, conf *Config) error {
	for _, b := range conf.files {
		out, err := findata.DecodeOne(b)
		if err != nil {
			return o.Err(ctx, "decode file", err)
		}

		b = out.TabTable(conf.view)
		fmt.Println(string(b))
	}
	return nil
}

type App struct {
	o      *observability.O
	render webstyle.Renderer
	dir    string
}

func New(ctx context.Context, o *observability.O, conf *Config) *App {
	return &App{
		o:      o,
		render: webstyle.NewRenderer(webstyle.TemplateCompact),
		dir:    conf.dir,
	}
}

func (a *App) Register(mux *http.ServeMux) {
	mux.Handle("/eur", otelhttp.NewHandler(httpencoding.Handler(a.hView("eur")), "hView - eur"))
	mux.Handle("/gbp", otelhttp.NewHandler(httpencoding.Handler(a.hView("gbp")), "hView - gbp"))
	mux.Handle("/twd", otelhttp.NewHandler(httpencoding.Handler(a.hView("twd")), "hView - twd"))
	mux.Handle("/", otelhttp.NewHandler(httpencoding.Handler(a.hIndex()), "hIndex"))
	mux.HandleFunc("/-/ready", func(rw http.ResponseWriter, r *http.Request) { rw.Write([]byte("ok")) })
}

func (a *App) hIndex() http.Handler {
	return http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
		ctx, span := a.o.T.Start(r.Context(), "hIndex")
		defer span.End()

		if r.URL.Path != "/" {
			http.Redirect(rw, r, "/", http.StatusFound)
			return
		}

		c := `
# fin

## money

### _fin_

- [GBP](/gbp)
- [EUR](/eur)
- [TWD](/twd)
`

		err := a.render.Render(rw, strings.NewReader(c), webstyle.Data{})
		if err != nil {
			a.o.HTTPErr(ctx, "render", err, rw, http.StatusInternalServerError)
		}
	})
}

func (a *App) hView(cur string) http.Handler {
	return http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
		ctx, span := a.o.T.Start(r.Context(), "hView")
		defer span.End()

		var out findata.Currency
		switch r.Method {
		case http.MethodPost:
			b, err := io.ReadAll(r.Body)
			if err != nil {
				a.o.HTTPErr(ctx, "read request", err, rw, http.StatusBadRequest)
				return
			}
			out, err = findata.DecodeOne(b)
			if err != nil {
				a.o.HTTPErr(ctx, "decode data", err, rw, http.StatusBadRequest)
				return
			}

			err = os.WriteFile(filepath.Join(a.dir, cur+".cue"), b, 0o644)
			if err != nil {
				a.o.HTTPErr(ctx, "save data", err, rw, http.StatusInternalServerError)
				return
			}

		case http.MethodGet:
			b, err := os.ReadFile(filepath.Join(a.dir, cur+".cue"))
			if err != nil {
				a.o.HTTPErr(ctx, "read data file", err, rw, http.StatusInternalServerError)
				return
			}
			out, err = findata.DecodeOne(b)
			if err != nil {
				a.o.HTTPErr(ctx, "decode data", err, rw, http.StatusNotFound)
				return
			}

		default:
			a.o.HTTPErr(ctx, "GET or POST", errors.New("bad method"), rw, http.StatusMethodNotAllowed)
			return
		}

		var buf bytes.Buffer
		buf.WriteString("# ")
		buf.WriteString(cur)
		buf.WriteString("\n\n## currency view\n\n### _")
		buf.WriteString(cur)
		buf.WriteString("_\n\n")

		buf.WriteString("\n#### _holdings_\n\n")
		buf.Write(out.MarkdownTable(findata.ViewHoldings))
		buf.WriteString("\n#### _expenses_\n\n")
		buf.Write(out.MarkdownTable(findata.ViewExpenses))
		buf.WriteString("\n#### _income_\n\n")
		buf.Write(out.MarkdownTable(findata.ViewIncomes))

		err := a.render.Render(rw, &buf, webstyle.Data{})
		if err != nil {
			a.o.HTTPErr(ctx, "render", err, rw, http.StatusInternalServerError)
			return
		}
	})
}
