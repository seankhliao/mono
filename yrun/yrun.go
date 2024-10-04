package yrun

import (
	"bytes"
	"context"
	"flag"
	"fmt"
	"log/slog"
	"net/http"
	"net/http/pprof"
	"os"
	"strings"
	"sync"
	"time"

	"cuelang.org/go/cue/cuecontext"
	"github.com/maragudk/gomponents"
	"github.com/maragudk/gomponents/html"
	"golang.org/x/sync/errgroup"
)

// RunConfig are the args passed to [Run].
// It takes 2 type parameters:
// C is the application config type,
// A is the application type.
type RunConfig[C, A any] struct {
	// Name is the application name
	// Name             string

	// Config should return the config to be used for the application,
	// being an parent [Config] embedding the application config
	// within the App field.
	// This uwll usually be a function wrapping one of
	// [FromBytes[Config[C]]] or [FromBucket[C]]
	Config func(context.Context) (Config[C], error)
	// New creates an application struct from the application config struct.
	New func(context.Context, C) (*A, error)
	// HTTP is for registering http handlers to the main listener
	HTTP func(*A, *http.ServeMux)
	// Debug is for registering http handlers to the debug handler
	Debug func(*A, func(string, http.Handler))
	// StartTasks should use the given function to start any background tasks.
	// Tasks should exit when the given context is canceled.
	StartTasks func(*A, context.Context, func(func() error))
	// RegisterShutdown should use the given function to start any tasks
	// that should run on shutdown.
	// shutdown tasks are given a context with a 5 second timeout.
	RegisterShutdown func(*A, context.Context, func(func(context.Context) error))

	// GRPC     func(*A, context.Context, *grpc.Server)
}

// Run is intended to be called as the sole function in main.
func Run[C, A any](r RunConfig[C, A]) (exitCode int) {
	var err error
	defer func() {
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			exitCode = 1
		}
	}()

	ctx := context.Background()

	var configBucket string
	var configPath string
	flag.StringVar(&configBucket, "config-bucket", "", "url reference to bucket") // TODO
	flag.StringVar(&configPath, "config-path", "", "path to config file in bucket")
	flag.Parse()
	if flag.NArg() > 0 {
		err = fmt.Errorf("unexpected args: %v", flag.Args())
		return
	}

	if r.Config == nil {
		if configBucket != "" && configPath != "" {
			r.Config = FromBucket[C](configBucket, configPath)
		} else {
			r.Config = defaultConfig[C]
		}
	}
	conf, err := r.Config(ctx)
	if err != nil {
		return
	}

	lg, lh, lz := conf.O11y.Log.New()

	var app *A
	if r.New != nil {
		app, err = r.New(ctx, conf.App)
		if err != nil {
			return
		}
	}

	group, groupCtx := errgroup.WithContext(ctx)

	if r.HTTP != nil {
		mux := http.NewServeMux()
		r.HTTP(app, mux)

		// add http server
		group.Go(func() error {
			httplh := lh.WithGroup("external-http")
			httplg := slog.New(httplh)

			server := &http.Server{
				Addr:              conf.HTTP.Address,
				Handler:           mux, // todo o11y
				ReadHeaderTimeout: 10 * time.Second,
				ErrorLog:          slog.NewLogLogger(httplh, slog.LevelWarn),
			}
			httplg.LogAttrs(ctx, slog.LevelInfo, "starting http server",
				slog.String("addr", server.Addr),
			)
			return server.ListenAndServe()
		})
	}

	if r.StartTasks != nil {
		lg.WithGroup("background-tasks").LogAttrs(ctx, slog.LevelInfo, "starting background tasks")
		r.StartTasks(app, ctx, group.Go)
	}

	// TODO: conditional creation?
	{
		handle, getMux := debugMux()
		// zpages
		handle("GET /debug/log", lz)
		handle("GET /debug/config", http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
			cuectx := cuecontext.New()
			val := cuectx.Encode(conf)
			fmt.Fprintln(rw, val)
		}))
		// pprof
		handle("GET /debug/pprof/", http.HandlerFunc(pprof.Index))
		handle("GET /debug/pprof/cmdline", http.HandlerFunc(pprof.Cmdline))
		handle("GET /debug/pprof/profile", http.HandlerFunc(pprof.Profile))
		handle("GET /debug/pprof/symbol", http.HandlerFunc(pprof.Symbol))
		handle("GET /debug/pprof/trace", http.HandlerFunc(pprof.Trace))

		if r.Debug != nil {
			r.Debug(app, handle)
		}

		// add debug server
		group.Go(func() error {
			httplh := lh.WithGroup("internal-http")
			httplg := slog.New(httplh)
			server := &http.Server{
				Addr:              conf.Debug.Address,
				Handler:           getMux(),
				ReadHeaderTimeout: 10 * time.Second,
				ErrorLog:          slog.NewLogLogger(httplh, slog.LevelWarn),
			}
			httplg.LogAttrs(ctx, slog.LevelInfo, "starting http server",
				slog.String("addr", server.Addr),
			)
			return server.ListenAndServe()
		})
	}

	if r.RegisterShutdown != nil {
		shutlg := lg.WithGroup("register-shutdown")
		shutlg.LogAttrs(ctx, slog.LevelInfo, "registering shutdown functions")
		r.RegisterShutdown(app, ctx, func(f func(context.Context) error) {
			group.Go(func() error {
				<-groupCtx.Done()
				timeOut := 5 * time.Second
				shutCtx := context.Background()
				shutCtx, cancel := context.WithTimeout(shutCtx, timeOut)
				defer cancel()
				shutlg.LogAttrs(ctx, slog.LevelInfo, "running shutdown function")
				return f(shutCtx)
			})
		})
	}

	err = group.Wait()
	return
}

func debugMux() (handle func(string, http.Handler), getMux func() *http.ServeMux) {
	mux := http.NewServeMux()
	var rendered bool
	var finalize sync.Once
	var links []gomponents.Node

	handle = func(s string, h http.Handler) {
		if rendered {
			panic("handle() called after getMux()")
		}
		mux.Handle(s, h)
		_, p, ok := strings.Cut(s, " ")
		if ok {
			s = p
		}
		links = append(links, html.Li(html.A(html.Href(s), gomponents.Text(s))))
	}

	getMux = func() *http.ServeMux {
		finalize.Do(func() {
			rendered = true
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
						html.Ul(),
					),
				),
			).Render(buf)
			index := buf.Bytes()
			t := time.Now()
			mux.HandleFunc("GET /{$}", func(w http.ResponseWriter, r *http.Request) {
				http.ServeContent(w, r, "index.html", t, bytes.NewReader(index))
			})
		})
		return mux
	}
	return handle, getMux
}
