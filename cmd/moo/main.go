package main

import (
	"context"
	_ "embed"
	"errors"
	"flag"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"net/http/pprof"
	"os"
	"os/signal"
	"syscall"

	"cuelang.org/go/cue"
	"cuelang.org/go/cue/cuecontext"
	"go.etcd.io/bbolt"
	"go.seankhliao.com/mono/httpencoding"
	"go.seankhliao.com/mono/webstyle/webstatic"
)

// main is the entrypoint to the application.
func main() {
	ctx := context.Background()
	ctx, stop := signal.NotifyContext(ctx, syscall.SIGTERM, syscall.SIGINT)
	defer stop()

	err := run(ctx, os.Args, os.Environ(), os.Stdout)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

// runs the application lifecycle, taking in system dependencies as arguments,
// and allows returning an error
//
// TODO: pass a rw filesystem as a dependency
func run(ctx context.Context, args, envs []string, out io.Writer) error {
	config, err := newConfig(ctx, args, envs)
	if err != nil {
		return fmt.Errorf("parse config: %w", err)
	}

	app, err := newApp(ctx, config, out)
	if err != nil {
		return fmt.Errorf("create app: %w", err)
	}

	err = app.Run(ctx)
	if err != nil {
		return fmt.Errorf("run app: %w", err)
	}

	return nil
}

type (
	Config struct {
		val cue.Value

		Data ConfigData
		HTTP ConfigHTTP
		Log  ConfigLog
	}
	ConfigData struct {
		Path string
	}
	ConfigHTTP struct {
		Addr string
	}
	ConfigLog struct {
		Format string
		Level  slog.Level
	}
)

// defaultConf is the default config used by the application
//
//go:embed default.cue
var defaultConf []byte

// newConfig converts input from flags into a config object.
//
// TODO: do something with environment variables
// TODO: pass the filesystem as a rw dependency
func newConfig(ctx context.Context, args, envs []string) (Config, error) {
	cuectx := cuecontext.New()
	val := cuectx.CompileBytes(defaultConf)
	if val.Err() != nil {
		return Config{}, fmt.Errorf("parse default config: %w", val.Err())
	}
	c := Config{
		val: val,
	}
	err := val.Decode(&c)
	if err != nil {
		return Config{}, fmt.Errorf("decode default config: %w", err)
	}

	fset := flag.NewFlagSet(args[0], flag.ContinueOnError)
	fset.Func("config", "path to config file", c.FlagFunc)

	err = fset.Parse(args[1:])
	if err != nil {
		return Config{}, fmt.Errorf("parse flags: %w", err)
	}

	return c, nil
}

// FlagFunc allows config to set its own value from a file path referencing a cue file.
func (c *Config) FlagFunc(s string) error {
	b, err := os.ReadFile(s)
	if err != nil {
		return fmt.Errorf("read confg file: %w", err)
	}
	cuectx := cuecontext.New()
	val := cuectx.CompileBytes(b)
	if val.Err() != nil {
		return fmt.Errorf("parse config file %q: %w", s, err)
	}
	c.val = c.val.Unify(val)
	if val.Err() != nil {
		return fmt.Errorf("unify config file %q: %w", s, err)
	}
	err = c.val.Decode(c)
	if err != nil {
		return fmt.Errorf("decode config file %q: %w", s, err)
	}
	return nil
}

func (c Config) ServeHTTP(rw http.ResponseWriter, r *http.Request) {
	cuectx := cuecontext.New()
	val := cuectx.Encode(c)
	fmt.Fprintln(rw, val)
}

func (c ConfigData) new() (*bbolt.DB, error) {
	db, err := bbolt.Open(c.Path, 0o644, nil)
	if err != nil {
		return nil, fmt.Errorf("open db: %w", err)
	}

	// TODO: schema setup?

	return db, nil
}

func (c ConfigHTTP) new(lh slog.Handler) (*http.Server, *http.ServeMux) {
	mux := http.NewServeMux()

	h := httpencoding.Handler(mux)

	svr := &http.Server{
		Addr:     c.Addr,
		Handler:  h,
		ErrorLog: slog.NewLogLogger(lh.WithGroup("nethttp"), slog.LevelWarn),
	}

	return svr, mux
}

func (c ConfigLog) new(out io.Writer) (*slog.Logger, slog.Handler) {
	opts := &slog.HandlerOptions{
		Level: c.Level,
	}
	var lh slog.Handler = slog.NewTextHandler(out, opts)
	switch c.Format {
	case "json":
		lh = slog.NewJSONHandler(out, opts)
	case "text":
		// default
	}
	lg := slog.New(lh)
	return lg, lh
}

type App struct {
	db   *bbolt.DB
	lg   *slog.Logger
	http *http.Server
}

func newApp(ctx context.Context, conf Config, out io.Writer) (*App, error) {
	lg, lh := conf.Log.new(out)

	db, err := conf.Data.new()
	if err != nil {
		return nil, fmt.Errorf("setup db: %w", err)
	}

	svr, mux := conf.HTTP.new(lh)

	// static content (fonts, stylesheets)
	webstatic.Register(mux)

	// debug endpoints
	mux.Handle("GET /debug/config", conf)
	// probes
	mux.Handle("GET /debug/liveness", http.HandlerFunc(handleLiveness))
	// pprof
	mux.Handle("GET /debug/pprof/", http.HandlerFunc(pprof.Index))
	mux.Handle("GET /debug/pprof/cmdline", http.HandlerFunc(pprof.Cmdline))
	mux.Handle("GET /debug/pprof/profile", http.HandlerFunc(pprof.Profile))
	mux.Handle("GET /debug/pprof/symbol", http.HandlerFunc(pprof.Symbol))
	mux.Handle("GET /debug/pprof/trace", http.HandlerFunc(pprof.Trace))

	return &App{
		db:   db,
		lg:   lg,
		http: svr,
	}, nil
}

func (a *App) Run(ctx context.Context) error {
	go func() {
		<-ctx.Done()
		a.lg.LogAttrs(ctx, slog.LevelInfo, "shutting down http server")
		a.http.Shutdown(context.Background())
	}()

	a.lg.LogAttrs(ctx, slog.LevelInfo, "starting http server", slog.String("address", a.http.Addr))
	err := a.http.ListenAndServe()
	if err != nil && !errors.Is(err, http.ErrServerClosed) {
		return fmt.Errorf("unclean http shutdown: %w", err)
	}

	return nil
}

func handleLiveness(rw http.ResponseWriter, r *http.Request) {
	io.WriteString(rw, "ok")
}
