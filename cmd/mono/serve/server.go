package serve

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"log/slog"
	"net/http"
	"time"

	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.seankhliao.com/mono/cmd/mono/ghdefaults"
	"go.seankhliao.com/mono/httpencoding"
	"go.seankhliao.com/mono/structflag"
	"go.seankhliao.com/mono/webstyle/webstatic"
)

// Run is the primary entrypoint to the serve command.
func Run(ctx context.Context, env, args []string, fsys fs.FS, stdout, stderr io.Writer) error {
	conf, err := NewConfig(args)
	if err != nil {
		return fmt.Errorf("parsing config: %w", err)
	}

	shutdown, lg, err := NewTelemetry(ctx, conf, stdout)
	if err != nil {
		return fmt.Errorf("setup telemetry: %w", err)
	}
	defer shutdown()

	svr, err := NewServer(ctx, conf, fsys)
	if err != nil {
		lg.Error("create server", "err", err)
		return fmt.Errorf("creating server: %w", err)
	}

	err = RunBackgroundTimers(ctx, conf)
	if err != nil {
		lg.Error("run background timers", "err", err)
		return fmt.Errorf("run timers: %w", err)
	}

	err = RunServer(ctx, lg, svr)
	if err != nil {
		lg.Error("run server", "err", err)
		return fmt.Errorf("run server: %w", err)
	}

	return nil
}

type (
	Config struct {
		HTTP ConfigHTTP
		Log  ConfigLog
		Data ConfigData

		// Auth       auth.Config
		GHDefaults ghdefaults.Config
	}

	ConfigData struct {
		Path string
	}

	ConfigHTTP struct {
		Addr string `flag:",http listen address [ip]:port"`
		// Grace int `flag:"grace.seconds"`
	}

	ConfigLog struct {
		Level slog.Level `flag:",log level for application logs"`
	}
)

// NewConfig parses arguments as flags into a [Config] struct.
// Args should not contain the program or subcommand name.
//
// TODO: implement support for env
func NewConfig(args []string) (Config, error) {
	conf := Config{
		HTTP: ConfigHTTP{
			Addr: ":8080",
		},
		Data: ConfigData{
			Path: "mono.bbolt",
		},
	}

	fset := flag.NewFlagSet("mono serve", flag.ContinueOnError)
	structflag.ConfigFile(fset, &conf)
	err := structflag.RegisterFlags(fset, &conf, "")
	if err != nil {
		return Config{}, fmt.Errorf("register flags: %w", err)
	}
	err = fset.Parse(args)
	if err != nil {
		return Config{}, fmt.Errorf("parse flags: %w", err)
	}

	return conf, nil
}

// NewServer creates a [net/http.Server] with all the routes registered.
func NewServer(ctx context.Context, c Config, fsys fs.FS) (*http.Server, error) {
	// TODO: can't use fs.FS which is read only, but databases are read-write
	db, err := NewStore(ctx, c.Data.Path)
	if err != nil {
		return nil, fmt.Errorf("opening store: %w", err)
	}
	_ = db

	mux := http.NewServeMux()
	webstatic.Register(mux)

	// authn
	// c.Auth.DB = db
	// ah, err := auth.New(c.Auth)
	// if err != nil {
	// 	// TODO
	// }
	// mux.Handle("GET /auth/{$}", ah.Index)
	// mux.Handle("POST /auth/loginstart", ah.LoginStart)
	// mux.Handle("POST /auth/loginend", ah.LoginEnd)
	// mux.Handle("POST /auth/registerstart", ah.RegisterStart)
	// mux.Handle("POST /auth/registerend", ah.RegisterEnd)
	// mux.Handle("POST /auth/registerremove", ah.RegisterRemove)
	// mux.Handle("GET /auth/logout/{$}", ah.Logout)

	// mux.Handle("GET /earbug/{$}")
	// mux.Handle("GET /earbug/artists")
	// mux.Handle("GET /earbug/callback")
	// mux.Handle("GET /earbug/export")
	// mux.Handle("GET /earbug/playbacks")
	// mux.Handle("GET /earbug/tracks")

	// mux.Handle("GET /ytfeed/feed/{feed}", ah.Check(yh.Feed))
	// mux.Handle("GET /ytfeed/lookup", ah.Check(yh.Lookup))

	// mux.Handle("GET /fin/{$}", ah.Check(fh.Index))
	// mux.Handle("GET /fin/{currency}/{$}", ah.Check(fh.View))
	// mux.Handle("POST /fin/{currency}/{$}", ah.Check(fh.Submit))

	gh := ghdefaults.New(c.GHDefaults)
	mux.Handle("POST /ghdefaults/webhook", gh.Webhook)

	// mux.Handle("GET /debug/pprof/", ah.Check(http.HandlerFunc(pprof.Index)))
	// mux.Handle("GET /debug/pprof/cmdline", ah.Check(http.HandlerFunc(pprof.Cmdline)))
	// mux.Handle("GET /debug/pprof/profile", ah.Check(http.HandlerFunc(pprof.Profile)))
	// mux.Handle("GET /debug/pprof/symbol", ah.Check(http.HandlerFunc(pprof.Symbol)))
	// mux.Handle("GET /debug/pprof/trace", ah.Check(http.HandlerFunc(pprof.Trace)))

	mux.Handle("GET /debug/liveness", writeOK())

	httpSvr := &http.Server{
		Addr:    c.HTTP.Addr,
		Handler: otelhttp.NewHandler(httpencoding.Handler(mux), "handle http"),
	}

	return httpSvr, nil
}

func writeOK() http.Handler {
	return http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
		io.WriteString(rw, "ok")
	})
}

// RunServer runs a [net/http.Server], blocking until it shuts down.
// Shutdown is triggered through context cancellation with a 5 second timeout.
func RunServer(ctx context.Context, lg *slog.Logger, svr *http.Server) error {
	errc := make(chan error, 1)
	go func() {
		<-ctx.Done()
		ctx := context.Background()
		timeout := 5 * time.Second
		ctx, cancel := context.WithTimeout(ctx, timeout)
		defer cancel()
		lg.Info("stopping http server", "addr", svr.Addr, "timeout", timeout)
		svr.Shutdown(ctx)
	}()
	go func() {
		lg.Info("starting http server", "addr", svr.Addr)
		err := svr.ListenAndServe()
		if err != nil && !errors.Is(err, http.ErrServerClosed) {
			errc <- err
			return
		}
		errc <- nil
	}()
	err := <-errc
	if err != nil {
		return fmt.Errorf("unclean shutdown: %w", err)
	}
	return nil
}
