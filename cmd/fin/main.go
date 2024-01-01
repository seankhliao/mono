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

	"github.com/maragudk/gomponents"
	"github.com/maragudk/gomponents/html"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.seankhliao.com/mono/authed"
	"go.seankhliao.com/mono/cmd/fin/findata"
	"go.seankhliao.com/mono/framework"
	"go.seankhliao.com/mono/httpencoding"
	"go.seankhliao.com/mono/observability"
	"go.seankhliao.com/mono/webstyle"
	"go.seankhliao.com/mono/webstyle/webstatic"
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

				mux := http.NewServeMux()
				webstatic.Register(mux)
				app.Register(mux)
				m.Handle("/", authed.New(o).Authed(mux))

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
	c.submitAddress, _ = url.Parse("https://fin.ihwa.liao.dev/")
	fset.Func("submit.addr", "base http addr to post to", func(s string) error {
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
	o   *observability.O
	dir string
}

func New(ctx context.Context, o *observability.O, conf *Config) *App {
	return &App{
		o:   o,
		dir: conf.dir,
	}
}

func (a *App) Register(mux *http.ServeMux) {
	mux.Handle("/eur", otelhttp.NewHandler(httpencoding.Handler(a.hView("eur")), "hView - eur"))
	mux.Handle("/gbp", otelhttp.NewHandler(httpencoding.Handler(a.hView("gbp")), "hView - gbp"))
	// mux.Handle("GET /twd", otelhttp.NewHandler(httpencoding.Handler(a.hView("twd")), "hView - twd"))
	mux.Handle("GET /{$}", otelhttp.NewHandler(httpencoding.Handler(a.hIndex()), "hIndex"))
}

func (a *App) hIndex() http.Handler {
	return http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
		_, span := a.o.T.Start(r.Context(), "hIndex")
		defer span.End()

		o := webstyle.NewOptions("fin", "fin", []gomponents.Node{
			html.H3(html.Em(gomponents.Text("fin"))),
			html.Ul(
				html.Li(html.A(html.Href("/gbp"), gomponents.Text("GBP"))),
				html.Li(html.A(html.Href("/eur"), gomponents.Text("EUR"))),
			),
		})
		webstyle.Structured(rw, o)
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

		o := webstyle.NewOptions("fin", cur, []gomponents.Node{
			html.H3(html.Em(gomponents.Text(cur))),
			html.H4(html.Em(gomponents.Text("income"))),
			out.HTMLTable(findata.ViewIncomes),
			html.H4(html.Em(gomponents.Text("expenses"))),
			out.HTMLTable(findata.ViewExpenses),
			html.H4(html.Em(gomponents.Text("holdings"))),
			out.HTMLTable(findata.ViewHoldings),
		})
		webstyle.Structured(rw, o)
	})
}
