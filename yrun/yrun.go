package yrun

import (
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"log/slog"
	"net"
	"net/http"
	"net/http/pprof"
	"os"
	"os/signal"
	"runtime/debug"
	"slices"
	"syscall"
	"time"

	"go.opentelemetry.io/contrib/instrumentation/google.golang.org/grpc/otelgrpc"
	"go.seankhliao.com/mono/yenv"
	"go.seankhliao.com/mono/yhttp"
	"go.seankhliao.com/mono/yo11y"
	"golang.org/x/sync/errgroup"
	"google.golang.org/grpc"
)

// Path to a config file.
// Must contain a json array of strings in key=value format
const EnvFileKey = "CONFIG_FILE"

type Task = func(context.Context) error

var DefaultEnv = []string{
	"HTTP_ADDR=:8080",
	"GRPC_ADDR=:8081",
	"DEBUG_ADDR=:8082",
	"LOG_FORMAT=text",
	"LOG_LEVEL=info",
	"TERMINATION_GRACE=5s",
}

// Config are the args passed to [Run].
// It takes 2 type parameters:
// C is the application config type,
// A is the application type.
type Config[C, A any] struct {
	HTTPAddr  string        `env:"HTTP_ADDR"`         // host:port
	GRPCAddr  string        `env:"GRPC_ADDR"`         // host:port
	DebugAddr string        `env:"DEBUG_ADDR"`        // host:port
	TermGrace time.Duration `env:"TERMINATION_GRACE"` // duration

	O11y   yo11y.Config
	Config C

	// New creates an application struct from the application config struct.
	New func(context.Context, C, yo11y.O11y) (*A, error)

	// GRPC is for registering grpc services
	GRPC  func(*A, context.Context, *grpc.Server)
	HTTP  func(*A, yhttp.Registrar)
	Debug func(*A, yhttp.Registrar)

	Background func(*A) []Task
	Shutdown   func(*A) []Task
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
	fileEnvs := envsFromFile(os.Getenv(EnvFileKey))
	envs := yenv.Map(slices.Concat(DefaultEnv, fileEnvs, os.Environ()))
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
	shutTasks := []Task{o11yRef.ShutTrace, o11yRef.ShutMetric}

	// signal handling
	ctx := context.Background()
	ctx, stop := signal.NotifyContext(ctx, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		<-ctx.Done()
		o11y.L.LogAttrs(ctx, slog.LevelInfo, "starting graceful shutdown",
			slog.String("reason", context.Cause(ctx).Error()),
		)
		// only handle once
		stop()
	}()

	// app setup
	app, err := runConfig.New(ctx, runConfig.Config, o11y)
	if err != nil {
		return fmt.Errorf("instantiate app: %w", err)
	}

	// group runner
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

	// Background tasks
	if runConfig.Background != nil {
		o11y.L.WithGroup("background-tasks").LogAttrs(ctx, slog.LevelInfo, "starting background tasks")
		for _, task := range runConfig.Background(app) {
			group.Go(func() error { return task(ctx) })
		}
	}

	// HTTP app
	if runConfig.HTTP != nil {
		mux := yhttp.New()

		runConfig.HTTP(app, mux)

		// add http server
		group.Go(func() error {
			httplh := o11y.H.WithGroup("external-http")
			httplg := slog.New(httplh)

			protos := new(http.Protocols)
			protos.SetHTTP1(true)
			protos.SetUnencryptedHTTP2(true)
			server := &http.Server{
				Addr:              runConfig.HTTPAddr,
				Handler:           mux,
				ReadHeaderTimeout: 10 * time.Second,
				ErrorLog:          slog.NewLogLogger(httplh, slog.LevelWarn),
				Protocols:         protos,
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
			rw.Header().Set("content-type", "text/plain")
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
			httplh := o11y.H.WithGroup("debug-http")
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

	// graceful shutdown handling
	if runConfig.Shutdown != nil {
		shutTasks = append(shutTasks, runConfig.Shutdown(app)...)
	}
	shutlg := o11y.L.WithGroup("register-shutdown")
	shutlg.LogAttrs(ctx, slog.LevelInfo, "registering shutdown functions")
	for _, task := range shutTasks {
		group.Go(func() error {
			// wait for termination of main tasks
			<-groupCtx.Done()

			// setup a new context
			timeOut := runConfig.TermGrace
			shutCtx := context.WithoutCancel(groupCtx)
			shutCtx, cancel := context.WithTimeout(shutCtx, timeOut)
			defer cancel()
			// start their shutdown
			shutlg.LogAttrs(ctx, slog.LevelInfo, "running shutdown function")
			return task(shutCtx)
		})
	}

	return group.Wait()
}

func envsFromFile(fn string) []string {
	if fn == "" {
		return nil
	}
	b, err := os.ReadFile(fn)
	if err != nil {
		return nil
	}
	var envs []string
	json.Unmarshal(b, &envs)
	return envs
}
