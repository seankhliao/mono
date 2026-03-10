package run

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
	"net/http/pprof"
	"net/netip"
	"os"
	"os/signal"
	"runtime/debug"
	"sync"
	"syscall"
	"time"

	"golang.org/x/crypto/acme"
	"golang.org/x/crypto/acme/autocert"
)

var (
	tsPrivate4 = netip.MustParsePrefix("100.64.0.0/10")
	tsPrivate6 = netip.MustParsePrefix("fd7a:115c:a1e0::/48")
)

type HTTP struct {
	TLSACME          bool
	TLSACMEServerURL string
	TLSACMEDir       string
	TLSACMEEABKey    string
	TLSACMEEABKID    string
	TLSACMEEmail     string
	TLSACMEAllow     []string
	HostPolicy       autocert.HostPolicy

	HTTPTLS           []string
	HTTPPlain         []string
	HTTPShutdownGrace time.Duration
}

func (h *HTTP) Flags(fset *flag.FlagSet) {
	fset.BoolVar(&h.TLSACME, "tls.acme", false, "enable TLS ACME autocert")
	fset.StringVar(&h.TLSACMEDir, "tls.acme.dir", "acme-tls", "path to directory to cache TLS certs")
	fset.StringVar(&h.TLSACMEServerURL, "tls.acme.url", "", "TLS ACME directory (server url)")
	fset.StringVar(&h.TLSACMEEmail, "tls.acme.email", "acme+nerys-monolith@liao.dev", "email to use for TLS ACME")
	fset.StringVar(&h.TLSACMEEABKID, "tls.acme.eab.kid", "", "TLS ACME EAB Key ID")
	fset.StringVar(&h.TLSACMEEABKey, "tls.acme.eab.key", "", "TLS ACME EAB Key (base64 encoded)")

	fset.Func("http.plain", "repeatable host:port addresses to listen on. host may be 'private' or 'public'", listenFlag(&h.HTTPPlain))
	fset.Func("http.tls", "repeatable host:port addresses to listen on. host may be 'private' or 'public'", listenFlag(&h.HTTPTLS))
	fset.DurationVar(&h.HTTPShutdownGrace, "http.shutdown.grace", 30*time.Second, "HTTP server graceful shutdown wait")
}

func (h *HTTP) Runner(logHandler slog.Handler, register func(*http.ServeMux)) Runner {
	return func(ctx context.Context, _ io.Reader, _, stderr io.Writer, _ fs.FS) error {
		sigc := make(chan os.Signal, 1)
		signal.Notify(sigc, syscall.SIGINT, syscall.SIGTERM)

		ctx, cancel := context.WithCancelCause(ctx)
		defer cancel(errors.New("end of run"))

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

		registerDebug(mux)
		register(mux)

		// var handler http.Handler
		handler := mux
		// TODO: wrap in instrumentation
		// TODO: register http handlers

		svr := &http.Server{
			Handler:     handler,
			ErrorLog:    slog.NewLogLogger(logHandler, slog.LevelWarn),
			BaseContext: func(l net.Listener) context.Context { return ctx },
			Protocols:   &http.Protocols{},
		}
		svr.Protocols.SetHTTP1(true)

		if h.TLSACME {
			log.LogAttrs(ctx, slog.LevelDebug, "enabling TLS with ACME",
				slog.String("acme_server_url", h.TLSACMEServerURL),
				slog.String("acme_cache", h.TLSACMEDir),
				slog.String("acme_email", h.TLSACMEEmail),
				slog.String("acme_eab_kid", h.TLSACMEEABKID),
			)
			if h.TLSACMEDir == "" || h.TLSACMEServerURL == "" {
				return fmt.Errorf("missing config for tls acme")
			}
			acmeMgr := autocert.Manager{
				Prompt: autocert.AcceptTOS,
				Cache:  autocert.DirCache(h.TLSACMEDir),
				Client: &acme.Client{
					HTTPClient:   client,
					DirectoryURL: h.TLSACMEServerURL,
				},
				Email:      h.TLSACMEEmail,
				HostPolicy: h.HostPolicy,
			}
			if h.TLSACMEEABKID != "" && len(h.TLSACMEEABKey) > 0 {
				key, err := base64.StdEncoding.DecodeString(h.TLSACMEEABKey)
				if err != nil {
					log.LogAttrs(ctx, slog.LevelError, "base64 decode TLS ACME EAB Key",
						slog.Any("err", err),
					)
					return fmt.Errorf("base64 decode TLS ACME EAB key: %w", err)
				}
				acmeMgr.ExternalAccountBinding = &acme.ExternalAccountBinding{
					KID: h.TLSACMEEABKID,
					Key: key, // TODO: confirm if this actually needs to be base64 decoded
				}
			}
			svr.TLSConfig = acmeMgr.TLSConfig()
			svr.Protocols.SetHTTP2(true)
		}

		var wg sync.WaitGroup
		for _, addr := range h.HTTPTLS {
			wg.Go(func() {
				defer cancel(errors.New("serveTLS returned"))

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
		for _, addr := range h.HTTPPlain {
			wg.Go(func() {
				defer cancel(errors.New("serve returned"))

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
		select {
		case <-ctx.Done():
			log.LogAttrs(ctx, slog.LevelWarn, "graceful shutdown triggered by cancel",
				slog.Any("err", context.Cause(ctx)),
			)
		case sig := <-sigc:
			log.LogAttrs(ctx, slog.LevelInfo, "starting graceful shutdown",
				slog.String("signal", sig.String()),
				slog.Duration("grace_period", h.HTTPShutdownGrace),
			)
		}

		// start graceful shutdown
		graceShutdownDone := make(chan struct{}, 1)
		wg.Go(func() {
			shutCtx := context.WithoutCancel(ctx)
			shutCtx, cancel := context.WithTimeoutCause(shutCtx, h.HTTPShutdownGrace, errors.New("shutdown grace reached"))
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

		case sig := <-sigc:
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
}

func listenFlag(addrFlag *[]string) func(string) error {
	return func(s string) error {
		host, port, err := net.SplitHostPort(s)
		if err != nil {
			return fmt.Errorf("not host:port %s: %w", s, err)
		}

		if host != "private" && host != "public" {
			*addrFlag = append(*addrFlag, s)
			return nil
		}
		ifaces, err := net.Interfaces()
		if err != nil {
			return fmt.Errorf("list interfaces: %w", err)
		}
		for _, iface := range ifaces {
			addrs, err := iface.Addrs()
			if err != nil {
				return fmt.Errorf("list addresses for interface %s: %w", iface.Name, err)
			}
			for _, addr := range addrs {
				prefix, err := netip.ParsePrefix(addr.String())
				if err != nil {
					return fmt.Errorf("parse address %s: %w", addr.String(), err)
				}
				ip := prefix.Addr()
				if ip.IsLinkLocalUnicast() {
					continue
				}
				isPrivate := ip.IsLoopback() || tsPrivate4.Contains(ip) || tsPrivate6.Contains(ip)
				if (host == "private" && isPrivate) || (host == "public" && !isPrivate) {
					*addrFlag = append(*addrFlag, net.JoinHostPort(ip.String(), port))
				}
			}
		}
		return nil
	}
}

func registerDebug(mux *http.ServeMux) {
	mux.Handle("GET /debug/buildinfo", privateOnly(http.HandlerFunc(buildInfo)))
	mux.Handle("GET /debug/pprof/", privateOnly(http.HandlerFunc(pprof.Index)))
	mux.Handle("GET /debug/pprof/cmdline", privateOnly(http.HandlerFunc(pprof.Cmdline)))
	mux.Handle("GET /debug/pprof/profile", privateOnly(http.HandlerFunc(pprof.Profile)))
	mux.Handle("GET /debug/pprof/symbol", privateOnly(http.HandlerFunc(pprof.Symbol)))
	mux.Handle("GET /debug/pprof/trace", privateOnly(http.HandlerFunc(pprof.Trace)))
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
