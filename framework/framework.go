package framework

import (
	"context"
	"flag"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"go.seankhliao.com/mono/framework/basehttp"
	"go.seankhliao.com/mono/observability"
)

type Config struct {
	RegisterFlags func(*flag.FlagSet)
	Start         func(context.Context, *observability.O, *http.ServeMux) (cleanup func(), err error)
}

func Run(c Config) {
	// configs
	fset := flag.NewFlagSet(os.Args[0], flag.ExitOnError)
	oconf := &observability.Config{}
	oconf.SetFlags(fset)
	hconf := &basehttp.Config{}
	hconf.SetFlags(fset)
	if c.RegisterFlags != nil {
		c.RegisterFlags(fset)
	}
	fset.Parse(os.Args[1:])
	if len(fset.Args()) > 0 {
		fmt.Fprintln(os.Stderr, "unexpected arguments:", fset.Args())
		os.Exit(1)
	}

	// observability
	o := observability.New(oconf)

	// run
	ctx := context.Background()
	err := func() error {
		// context
		ctx, stop := signal.NotifyContext(ctx, syscall.SIGINT, syscall.SIGTERM)
		defer stop()

		h := basehttp.New(ctx, o, hconf)

		if c.Start != nil {
			cleanup, err := c.Start(ctx, o, h.Mux)
			if err != nil {
				return o.Err(ctx, "app start", err)
			}
			if cleanup != nil {
				defer cleanup()
			}
		}

		err := h.Run(ctx)
		if err != nil {
			return o.Err(ctx, "app run", err)
		}
		return nil
	}()
	if err != nil {
		o.Err(ctx, "exiting with error", err)
		os.Exit(1)
	}
}
