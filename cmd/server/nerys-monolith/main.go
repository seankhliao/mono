package main

import (
	"context"
	"encoding/base64"
	"errors"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"log/slog"
	"net"
	"net/http"
	"net/http/httputil"
	"net/http/pprof"
	"net/netip"
	"os"
	"os/signal"
	"path/filepath"
	"runtime/debug"
	"strconv"
	"sync"
	"syscall"
	"time"

	"go.seankhliao.com/mono/run"
	"golang.org/x/crypto/acme"
	"golang.org/x/crypto/acme/autocert"
)

func main() {
	run.OSExec(&run.CommandGroup{
		Name: "nerys-monolith",
		Desc: "a bundle of all the servers to run on nerys.",
		Subs: []run.Commander{
			&run.CommandBasic[ServeConfig]{
				Name:  "serve",
				Desc:  "serve the web",
				Flags: (*ServeConfig).Flags,
				Do:    (*ServeConfig).Do,
			},
		},
	})
}

type ServeConfig struct {
	LogLevel slog.LevelVar

	TLSACME          bool
	TLSACMEDirectory string
	TLSACMEDir       string
	TLSACMEEABKey    string
	TLSACMEEABKID    string
	TLSACMEEmail     string

	HTTPTLS           int
	HTTPPlain         int
	HTTPShutdownGrace time.Duration
}

func (s *ServeConfig) Flags(fset *flag.FlagSet) error {
	fset.TextVar(&s.LogLevel, "log.level", &s.LogLevel, "log level")

	fset.BoolVar(&s.TLSACME, "tls.acme", false, "enable TLS ACME autocert")
	fset.StringVar(&s.TLSACMEDir, "tls.acme.dir", "acme-tls", "path to directory to cache TLS certs")
	fset.StringVar(&s.TLSACMEDir, "tls.acme.url", "", "TLS ACME directory (server url)")
	fset.StringVar(&s.TLSACMEEmail, "tls.acme.email", "acme+nerys-monolith@liao.dev", "email to use for TLS ACME")
	fset.StringVar(&s.TLSACMEEABKID, "tls.acme.eab.kid", "", "TLS ACME EAB Key ID")
	fset.StringVar(&s.TLSACMEEABKey, "tls.acme.eab.key", "", "TLS ACME EAB Key (base64 encoded)")

	fset.IntVar(&s.HTTPTLS, "http.tls", 443, "port to serve HTTP over TLS, -1 to disable")
	fset.IntVar(&s.HTTPPlain, "http.plain", -1, "port to serve HTTP over plaintext, -1 to disable")
	fset.DurationVar(&s.HTTPShutdownGrace, "http.shutdown.grace", 30*time.Second, "HTTP server graceful shutdown wait")
	return nil
}

func (s *ServeConfig) Do() run.Runner {
	return func(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) int {
		err := s.Run(ctx, stdin, stdout, stderr, fsys)
		if err != nil {
			return 1
		}
		return 0
	}
}

func (s *ServeConfig) Run(ctx context.Context, _ io.Reader, _, stderr io.Writer, _ fs.FS) error {
	sigc := make(chan os.Signal, 1)
	signal.Notify(sigc, syscall.SIGINT, syscall.SIGTERM)

	ctx, cancel := context.WithCancelCause(ctx)
	defer cancel(errors.New("end of run"))

	logHandler := slog.NewTextHandler(stderr, &slog.HandlerOptions{
		Level: &s.LogLevel,
	})
	log := slog.New(logHandler)

	client := &http.Client{}
	transport := &http.Transport{
		Protocols:         &http.Protocols{},
		ForceAttemptHTTP2: true,
	}
	transport.Protocols.SetHTTP1(true)
	transport.Protocols.SetHTTP2(true)
	client.Transport = transport
	// TODO: wrap in instrumentation

	mux := http.NewServeMux()

	mux.Handle("GET /debug/buildinfo", privateOnly()(http.HandlerFunc(buildInfo)))
	mux.Handle("GET /debug/pprof/", privateOnly()(http.HandlerFunc(pprof.Index)))
	mux.Handle("GET /debug/pprof/cmdline", privateOnly()(http.HandlerFunc(pprof.Cmdline)))
	mux.Handle("GET /debug/pprof/profile", privateOnly()(http.HandlerFunc(pprof.Profile)))
	mux.Handle("GET /debug/pprof/symbol", privateOnly()(http.HandlerFunc(pprof.Symbol)))
	mux.Handle("GET /debug/pprof/trace", privateOnly()(http.HandlerFunc(pprof.Trace)))

	mux.HandleFunc("GET /{$}", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "hello world")
	})

	mux.HandleFunc("GET /test-fs", func(w http.ResponseWriter, r *http.Request) {
		name := filepath.Join("/var/lib/nerys-monolith", "fs-check")
		b, _ := httputil.DumpRequest(r, false)
		os.WriteFile(name, b, 0o644)
		f, err := os.Open(name)
		if err != nil {
			fmt.Fprintln(w, err)
			return
		}
		defer f.Close()
		io.Copy(w, f)
	})

	var h http.Handler
	h = mux
	// TODO: wrap in instrumentation
	// TODO: register http handlers

	svr := &http.Server{
		Handler:     h,
		ErrorLog:    slog.NewLogLogger(logHandler, slog.LevelWarn),
		BaseContext: func(l net.Listener) context.Context { return ctx },
		Protocols:   &http.Protocols{},
	}
	svr.Protocols.SetHTTP1(true)

	if s.TLSACME {
		log.LogAttrs(ctx, slog.LevelDebug, "enabling TLS with ACME",
			slog.String("acme_directory", s.TLSACMEDirectory),
			slog.String("acme_email", s.TLSACMEEmail),
			slog.String("acme_eab_kid", s.TLSACMEEABKID),
		)
		acmeMgr := autocert.Manager{
			Prompt: autocert.AcceptTOS,
			Cache:  autocert.DirCache(s.TLSACMEDir),
			Client: &acme.Client{
				HTTPClient:   client,
				DirectoryURL: s.TLSACMEDirectory,
			},
			Email: s.TLSACMEEmail,
		}
		if s.TLSACMEEABKID != "" && len(s.TLSACMEEABKey) > 0 {
			key, err := base64.StdEncoding.DecodeString(s.TLSACMEEABKey)
			if err != nil {
				log.LogAttrs(ctx, slog.LevelError, "base64 decode TLS ACME EAB Key",
					slog.Any("err", err),
				)
				return fmt.Errorf("base64 decode TLS ACME EAB key: %w", err)
			}
			acmeMgr.ExternalAccountBinding = &acme.ExternalAccountBinding{
				KID: s.TLSACMEEABKID,
				Key: key,
			}
		}
		svr.TLSConfig = acmeMgr.TLSConfig()
		svr.Protocols.SetHTTP2(true)
	}

	var wg sync.WaitGroup
	if s.HTTPTLS >= 0 {
		wg.Go(func() {
			defer cancel(errors.New("serveTLS returned"))

			addr := net.JoinHostPort("", strconv.Itoa(s.HTTPTLS))
			lis, err := net.Listen("tcp", addr)
			if err != nil {
				log.LogAttrs(ctx, slog.LevelError, "listen tcp for ServeTLS",
					slog.String("addr", addr),
					slog.Any("err", err),
				)
				cancel(fmt.Errorf("listen tcp %s: %w", addr, err))
				return
			}

			log.LogAttrs(ctx, slog.LevelInfo, "ServeTLS starting",
				slog.String("addr", lis.Addr().String()),
			)
			err = svr.ServeTLS(lis, "", "")
			if err != nil {
				if !errors.Is(err, http.ErrServerClosed) {
					log.LogAttrs(ctx, slog.LevelError, "ServeTLS unexpected error",
						slog.String("addr", lis.Addr().String()),
						slog.Any("err", err),
					)
					return
				}
				log.LogAttrs(ctx, slog.LevelInfo, "ServeTLS returned",
					slog.String("addr", lis.Addr().String()),
				)
			}
		})
	}
	if s.HTTPPlain >= 0 {
		wg.Go(func() {
			defer cancel(errors.New("serve returned"))

			addr := net.JoinHostPort("", strconv.Itoa(s.HTTPPlain))
			lis, err := net.Listen("tcp", addr)
			if err != nil {
				log.LogAttrs(ctx, slog.LevelError, "listen tcp for Serve",
					slog.String("addr", addr),
					slog.Any("err", err),
				)
				cancel(fmt.Errorf("listen tcp %s: %w", addr, err))
				return
			}

			log.LogAttrs(ctx, slog.LevelInfo, "Serve starting",
				slog.String("addr", lis.Addr().String()),
			)
			err = svr.Serve(lis)
			if err != nil {
				if !errors.Is(err, http.ErrServerClosed) {
					log.LogAttrs(ctx, slog.LevelError, "Serve unexpected error",
						slog.String("addr", lis.Addr().String()),
						slog.Any("err", err),
					)
					return
				}
				log.LogAttrs(ctx, slog.LevelInfo, "Serve returned",
					slog.String("addr", lis.Addr().String()),
				)
			}
		})
	}

	// wait for termination
	log.LogAttrs(ctx, slog.LevelDebug, "waiting for shutdown signal")
	sig := <-sigc
	log.LogAttrs(ctx, slog.LevelInfo, "starting graceful shutdown",
		slog.String("signal", sig.String()),
		slog.Duration("grace_period", s.HTTPShutdownGrace),
	)

	// start graceful shutdown
	graceShutdownDone := make(chan struct{}, 1)
	wg.Go(func() {
		shutCtx := context.WithoutCancel(ctx)
		shutCtx, cancel := context.WithTimeoutCause(shutCtx, s.HTTPShutdownGrace, errors.New("shutdown grace reached"))
		defer cancel()

		err := svr.Shutdown(shutCtx)
		if err != nil {
			log.LogAttrs(ctx, slog.LevelError, "http server shutdown errored",
				slog.Any("err", err),
			)
		}
		graceShutdownDone <- struct{}{}
	})

	select {
	case <-graceShutdownDone:
		log.LogAttrs(ctx, slog.LevelInfo, "graceful shutdown complete")

	case sig = <-sigc:
		// force a shutdown
		signal.Stop(sigc)
		log.LogAttrs(ctx, slog.LevelWarn, "got second signal, forcing shutdown",
			slog.String("signal", sig.String()),
		)
		wg.Go(func() {
			err := svr.Close()
			if err != nil {
				log.LogAttrs(ctx, slog.LevelError, "server force shutdown returned an error",
					slog.Any("err", err),
				)
			}
		})
	}

	log.LogAttrs(ctx, slog.LevelDebug, "waiting for shutdown to finish")
	wg.Wait()

	log.LogAttrs(ctx, slog.LevelInfo, "shutdown complete")
	return nil
}

var (
	tsPrivate4 = netip.MustParsePrefix("100.64.0.0/10")
	tsPrivate6 = netip.MustParsePrefix("fd7a:115c:a1e0::/48")
)

func privateOnly() func(http.Handler) http.Handler {
	return func(h http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			remoteHost, _, _ := net.SplitHostPort(r.RemoteAddr)
			remoteAddr, err := netip.ParseAddr(remoteHost)
			if err != nil {
				http.Error(w, "failed to parse remote addr", http.StatusUnauthorized)
				return
			}
			if !remoteAddr.IsLoopback() && !tsPrivate4.Contains(remoteAddr) && !tsPrivate6.Contains(remoteAddr) {
				http.Error(w, "request not from private address", http.StatusUnauthorized)
				return
			}

			h.ServeHTTP(w, r)
		})
	}
}

func buildInfo(rw http.ResponseWriter, r *http.Request) {
	rw.Header().Set("content-type", "text/plain")
	bi, ok := debug.ReadBuildInfo()
	if !ok {
		fmt.Fprintln(rw, "no embedded build info")
		return
	}
	fmt.Fprintln(rw, bi)
}
