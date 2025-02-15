package yrun

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"log/slog"
	"net"
	"net/http"
	"net/http/pprof"
	"net/url"
	"os"
	"os/signal"
	"runtime/debug"
	"syscall"
	"time"

	"go.opentelemetry.io/contrib/instrumentation/google.golang.org/grpc/otelgrpc"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.seankhliao.com/mono/yenv"
	"go.seankhliao.com/mono/yhttp"
	"go.seankhliao.com/mono/yo11y"
	"gocloud.dev/blob"
	"gocloud.dev/blob/fileblob"
	_ "gocloud.dev/blob/gcsblob"
	_ "gocloud.dev/blob/memblob"
	"golang.org/x/sync/errgroup"
	"google.golang.org/grpc"
)

// Config are the args passed to [Run].
// It takes 2 type parameters:
// C is the application config type,
// A is the application type.
type Config[C, A any] struct {
	HTTPAddr  string `env:"HTTP_ADDR"`  // host:port
	GRPCAddr  string `env:"GRPC_ADDR"`  // host:port
	DebugAddr string `env:"DEBUG_ADDR"` // host:port

	Store string `env:"STORAGE_DIR"`

	O11y   yo11y.Config
	Config C

	// New creates an application struct from the application config struct.
	New func(context.Context, C, *blob.Bucket, yo11y.O11y) (*A, error)

	// GRPC is for registering grpc services
	GRPC  func(*A, context.Context, *grpc.Server)
	HTTP  func(*A, yhttp.Registrar)
	Debug func(*A, yhttp.Registrar)

	Background func(*A) []func(context.Context) error
	Shutdown   func(*A) []func(context.Context) error
}

// Run is intended to be called as the sole function in main.
func Run[C, A any](r Config[C, A]) (exitCode int) {
	err := run(r)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		exitCode = 1
	}
	return
}

func run[AppConfig, App any](runConfig Config[AppConfig, App]) error {
	// config from env
	envs := yenv.Map(append([]string{
		"HTTP_ADDR=:8080",
		"GRPC_ADDR=:8081",
		"DEBUG_ADDR=:8082",
		"STORAGE_DIR=/data",
		"LOG_FORMAT=text",
		"LOG_LEVEL=info",
	}, os.Environ()...))
	err := yenv.FromEnv(envs, "", &runConfig)
	if err != nil {
		return fmt.Errorf("process config from env: %w", err)
	}

	// command line
	flag.Parse()
	if flag.NArg() > 0 {
		return fmt.Errorf("unexpected args: %v", flag.Args())
	}

	// o11y
	o11y, o11yRef := yo11y.New(runConfig.O11y)
	// TODO: trigger o11y shutdown

	// signal handling, groyp runner
	ctx := context.Background()
	ctx, stop := signal.NotifyContext(ctx, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		// only handle once
		<-ctx.Done()
		stop()
	}()

	// storage
	bkt, err := (&fileblob.URLOpener{
		Options: fileblob.Options{
			NoTempDir: true,
		},
	}).OpenBucketURL(ctx, &url.URL{
		Scheme: fileblob.Scheme,
		Path:   runConfig.Store,
	})
	// bkt, err := blob.OpenBucket(ctx, "file://"+runConfig.Store)
	if err != nil {
		return fmt.Errorf("open storage dir: %w", err)
	}

	// app setup
	app, err := runConfig.New(ctx, runConfig.Config, bkt, o11y)
	if err != nil {
		return fmt.Errorf("instantiate app: %w", err)
	}

	group, groupCtx := errgroup.WithContext(ctx)

	// gRPC app
	if runConfig.GRPC != nil {
		statsHandler := otelgrpc.NewServerHandler()
		server := grpc.NewServer(grpc.StatsHandler(statsHandler))

		runConfig.GRPC(app, ctx, server)

		group.Go(func() error {
			lis, err := net.Listen("tcp", runConfig.GRPCAddr)
			if err != nil {
				return fmt.Errorf("grpc: listen on %s: %w", runConfig.GRPCAddr, err)
			}

			o11y.L.WithGroup("grpc").LogAttrs(ctx, slog.LevelInfo, "starting grpc server",
				slog.String("addr", runConfig.GRPCAddr),
			)
			return server.Serve(lis)
		})

	}

	// HTTP app
	if runConfig.HTTP != nil {
		mux := yhttp.New()

		runConfig.HTTP(app, mux)

		// add http server
		group.Go(func() error {
			httplh := o11y.H.WithGroup("external-http")
			httplg := slog.New(httplh)

			server := &http.Server{
				Addr:              runConfig.HTTPAddr,
				Handler:           otelhttp.NewHandler(mux, "serve http"),
				ReadHeaderTimeout: 10 * time.Second,
				ErrorLog:          slog.NewLogLogger(httplh, slog.LevelWarn),
			}

			group.Go(func() error {
				<-ctx.Done()
				shutCtx := context.Background()
				return server.Shutdown(shutCtx)
			})

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
	if runConfig.Background != nil {
		o11y.L.WithGroup("background-tasks").LogAttrs(ctx, slog.LevelInfo, "starting background tasks")
		for _, task := range runConfig.Background(app) {
			group.Go(func() error { return task(ctx) })
		}
	}

	// Debug http server
	{
		mux := yhttp.Debug()
		// zpages
		mux.Pattern("GET", "", "/debug/log/", o11yRef.LogZpage.ServeHTTP)
		mux.Pattern("GET", "", "/debug/trace/", o11yRef.TraceZpage.ServeHTTP)
		mux.Pattern("GET", "", "/debug/config", func(rw http.ResponseWriter, r *http.Request) {
			rw.Header().Set("content-type", "text/plain")
			envs := yenv.Print("", runConfig)
			for _, env := range envs {
				fmt.Fprintln(rw, env)
			}
		})
		mux.Pattern("GET", "", "/debug/buildinfo", func(rw http.ResponseWriter, r *http.Request) {
			bi, ok := debug.ReadBuildInfo()
			if !ok {
				fmt.Fprintln(rw, "no embedded build info")
				return
			}
			fmt.Fprintln(rw, bi)
		})
		// pprof
		mux.Pattern("GET", "", "/debug/pprof/", http.HandlerFunc(pprof.Index).ServeHTTP)
		mux.Pattern("GET", "", "/debug/pprof/cmdline", http.HandlerFunc(pprof.Cmdline).ServeHTTP)
		mux.Pattern("GET", "", "/debug/pprof/profile", http.HandlerFunc(pprof.Profile).ServeHTTP)
		mux.Pattern("GET", "", "/debug/pprof/symbol", http.HandlerFunc(pprof.Symbol).ServeHTTP)
		mux.Pattern("GET", "", "/debug/pprof/trace", http.HandlerFunc(pprof.Trace).ServeHTTP)

		if runConfig.Debug != nil {
			runConfig.Debug(app, mux)
		}

		// add debug server
		group.Go(func() error {
			httplh := o11y.H.WithGroup("internal-http")
			httplg := slog.New(httplh)
			server := &http.Server{
				Addr:              runConfig.DebugAddr,
				Handler:           mux,
				ReadHeaderTimeout: 10 * time.Second,
				ErrorLog:          slog.NewLogLogger(httplh, slog.LevelWarn),
			}

			group.Go(func() error {
				<-ctx.Done()
				shutCtx := context.Background()
				return server.Shutdown(shutCtx)
			})

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

	if runConfig.Shutdown != nil {
		shutlg := o11y.L.WithGroup("register-shutdown")
		shutlg.LogAttrs(ctx, slog.LevelInfo, "registering shutdown functions")
		for _, task := range runConfig.Shutdown(app) {
			group.Go(func() error {
				<-groupCtx.Done()
				timeOut := 5 * time.Second
				shutCtx := context.Background()
				shutCtx, cancel := context.WithTimeout(shutCtx, timeOut)
				defer cancel()
				shutlg.LogAttrs(ctx, slog.LevelInfo, "running shutdown function")
				return task(shutCtx)
			})
		}
	}

	return group.Wait()
}
