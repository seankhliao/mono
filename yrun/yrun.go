package yrun

import (
	"context"
	"flag"
	"fmt"
	"log/slog"
	"net/http"
	"net/http/pprof"
	"os"
	"time"

	"cuelang.org/go/cue/cuecontext"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
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
	New func(context.Context, C, O11y) (*A, error)
	// HTTP is for registering http handlers to the main listener
	HTTP func(*A, HTTPRegistrar)
	// Debug is for registering http handlers to the debug handler
	Debug func(*A, HTTPRegistrar)
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

	o11y, o11yRef := NewO11y(conf.O11y)

	var app *A
	if r.New != nil {
		app, err = r.New(ctx, conf.App, o11y)
		if err != nil {
			return
		}
	}

	group, groupCtx := errgroup.WithContext(ctx)

	if r.HTTP != nil {
		mux := http.NewServeMux()
		r.HTTP(app, &muxRegister{mux})

		// add http server
		group.Go(func() error {
			httplh := o11y.H.WithGroup("external-http")
			httplg := slog.New(httplh)

			server := &http.Server{
				Addr:              conf.HTTP.Address,
				Handler:           otelhttp.NewHandler(mux, "serve http"),
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
		o11y.L.WithGroup("background-tasks").LogAttrs(ctx, slog.LevelInfo, "starting background tasks")
		r.StartTasks(app, ctx, group.Go)
	}

	// TODO: conditional creation?
	{
		mx, getMux := debugMux()
		// zpages
		mx.Pattern("GET", "", "/debug/log/", o11yRef.LogZpage)
		mx.Pattern("GET", "", "/debug/trace/", o11yRef.TraceZpage)
		mx.Pattern("GET", "", "/debug/config", http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
			cuectx := cuecontext.New()
			val := cuectx.Encode(conf)
			fmt.Fprintln(rw, val)
		}))
		// pprof
		mx.Pattern("GET", "", "/debug/pprof/", http.HandlerFunc(pprof.Index))
		mx.Pattern("GET", "", "/debug/pprof/cmdline", http.HandlerFunc(pprof.Cmdline))
		mx.Pattern("GET", "", "/debug/pprof/profile", http.HandlerFunc(pprof.Profile))
		mx.Pattern("GET", "", "/debug/pprof/symbol", http.HandlerFunc(pprof.Symbol))
		mx.Pattern("GET", "", "/debug/pprof/trace", http.HandlerFunc(pprof.Trace))

		if r.Debug != nil {
			r.Debug(app, mx)
		}

		// add debug server
		group.Go(func() error {
			httplh := o11y.H.WithGroup("internal-http")
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
		shutlg := o11y.L.WithGroup("register-shutdown")
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
