package yrun

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"log/slog"
	"net/http"
	"net/http/pprof"
	"os"
	"os/signal"
	"syscall"
	"time"

	"cuelang.org/go/cue/cuecontext"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"gocloud.dev/blob"
	_ "gocloud.dev/blob/fileblob"
	_ "gocloud.dev/blob/gcsblob"
	_ "gocloud.dev/blob/memblob"
	"golang.org/x/sync/errgroup"
)

// RunConfig are the args passed to [Run].
// It takes 2 type parameters:
// C is the application config type,
// A is the application type.
type RunConfig[C, A any] struct {
	// Name is the application name
	// Name             string

	// A cue schema, all config should be under the "App" key.
	AppConfigSchema string
	// New creates an application struct from the application config struct.
	New func(context.Context, C, *blob.Bucket, O11y) (*A, error)
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
	err := run(r)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		exitCode = 1
	}
	return
}

func run[AppConfig, App any](runConfig RunConfig[AppConfig, App]) error {
	ctx := context.Background()

	// command line
	var configBucket string
	var configPath string
	flag.StringVar(&configBucket, "config-bucket", "file://", "url reference to bucket (file:// or gs://)")
	flag.StringVar(&configPath, "config-path", "config.cue", "path to config file in bucket")
	flag.Parse()
	if flag.NArg() > 0 {
		return fmt.Errorf("unexpected args: %v", flag.Args())
	}

	// storage
	bkt, err := blob.OpenBucket(ctx, configBucket)
	if err != nil {
		return fmt.Errorf("open config bucket %q: %w", configBucket, err)
	}
	defer bkt.Close()

	// config file
	var configBytes []byte
	if configPath != "" {
		configBytes, err = bkt.ReadAll(ctx, configPath)
		if err != nil {
			return fmt.Errorf("read config file bucket = %q path = %q: %w", configBucket, configPath, err)
		}
	}
	config, err := FromBytes[Config[AppConfig]](baseSchema, runConfig.AppConfigSchema, configBytes)
	if err != nil {
		return fmt.Errorf("parse config file: %w", err)
	}

	// o11y
	o11y, o11yRef := NewO11y(config.O11y)

	// signal handling, groyp runner
	ctx, stop := signal.NotifyContext(ctx, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		// only handle once
		<-ctx.Done()
		stop()
	}()

	// app setup
	app, err := runConfig.New(ctx, config.App, bkt, o11y)
	if err != nil {
		return fmt.Errorf("instantiate app: %w", err)
	}

	group, groupCtx := errgroup.WithContext(ctx)

	// HTTP app
	if runConfig.HTTP != nil {
		mux := http.NewServeMux()
		mx := &muxRegister{mux, make(map[string]struct{})}
		runConfig.HTTP(app, mx)

		// add http server
		group.Go(func() error {
			httplh := o11y.H.WithGroup("external-http")
			httplg := slog.New(httplh)

			if config.HTTP.K8s.Enable {
				httplg.LogAttrs(ctx, slog.LevelDebug, "managing k8s service/httproute")
				err := ManageK8s(ctx, httplg, config.HTTP, mx)
				if err != nil {
					return fmt.Errorf("manage k8s httproute: %w", err)
				}
			}

			server := &http.Server{
				Addr:              config.HTTP.Address,
				Handler:           otelhttp.NewHandler(mux, "serve http"),
				ReadHeaderTimeout: 10 * time.Second,
				ErrorLog:          slog.NewLogLogger(httplh, slog.LevelWarn),
			}
			httplg.LogAttrs(ctx, slog.LevelInfo, "starting http server",
				slog.String("addr", server.Addr),
			)
			err := server.ListenAndServe()
			if err == nil || errors.Is(err, http.ErrServerClosed) {
				return nil
			}
			return err
		})
	}

	// Background tasks
	if runConfig.StartTasks != nil {
		o11y.L.WithGroup("background-tasks").LogAttrs(ctx, slog.LevelInfo, "starting background tasks")
		runConfig.StartTasks(app, ctx, group.Go)
	}

	// Debug http server
	{
		mx, getMux := debugMux()
		// zpages
		mx.Pattern("GET", "", "/debug/log/", o11yRef.LogZpage.ServeHTTP)
		mx.Pattern("GET", "", "/debug/trace/", o11yRef.TraceZpage.ServeHTTP)
		mx.Pattern("GET", "", "/debug/config", func(rw http.ResponseWriter, r *http.Request) {
			cuectx := cuecontext.New()
			val := cuectx.Encode(config)
			fmt.Fprintln(rw, val)
		})
		// pprof
		mx.Pattern("GET", "", "/debug/pprof/", http.HandlerFunc(pprof.Index).ServeHTTP)
		mx.Pattern("GET", "", "/debug/pprof/cmdline", http.HandlerFunc(pprof.Cmdline).ServeHTTP)
		mx.Pattern("GET", "", "/debug/pprof/profile", http.HandlerFunc(pprof.Profile).ServeHTTP)
		mx.Pattern("GET", "", "/debug/pprof/symbol", http.HandlerFunc(pprof.Symbol).ServeHTTP)
		mx.Pattern("GET", "", "/debug/pprof/trace", http.HandlerFunc(pprof.Trace).ServeHTTP)

		if runConfig.Debug != nil {
			runConfig.Debug(app, mx)
		}

		// add debug server
		group.Go(func() error {
			httplh := o11y.H.WithGroup("internal-http")
			httplg := slog.New(httplh)
			server := &http.Server{
				Addr:              config.Debug.Address,
				Handler:           getMux(),
				ReadHeaderTimeout: 10 * time.Second,
				ErrorLog:          slog.NewLogLogger(httplh, slog.LevelWarn),
			}
			httplg.LogAttrs(ctx, slog.LevelInfo, "starting http server",
				slog.String("addr", server.Addr),
			)
			err := server.ListenAndServe()
			if err == nil || errors.Is(err, http.ErrServerClosed) {
				return nil
			}
			return err
		})
	}

	if runConfig.RegisterShutdown != nil {
		shutlg := o11y.L.WithGroup("register-shutdown")
		shutlg.LogAttrs(ctx, slog.LevelInfo, "registering shutdown functions")
		runConfig.RegisterShutdown(app, ctx, func(f func(context.Context) error) {
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

	return group.Wait()
}
