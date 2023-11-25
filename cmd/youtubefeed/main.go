// Sample Go code for user authorization

package main

import (
	"context"
	_ "embed"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"os"

	"go.seankhliao.com/mono/framework"
	"go.seankhliao.com/mono/observability"
)

func main() {
	conf := &Config{}
	framework.Run(framework.Config{
		RegisterFlags: conf.SetFlags,
		Start: func(ctx context.Context, o *observability.O, sm *http.ServeMux) (cleanup func(), err error) {
			if len(conf.Feeds) == 0 {
				err := conf.setConfig([]byte(defaultConfig))
				if err != nil {
					o.Err(ctx, "set default config", err)
					os.Exit(1)
				}
			}

			app, err := New(ctx, o, conf)
			if err != nil {
				o.Err(ctx, "setup app", err)
				os.Exit(1)
			}

			switch conf.mode {
			case "lookup":
				res, err := app.lookupFromConfig(ctx)
				if err != nil {
					o.Err(ctx, "lookup", err)
					os.Exit(1)
				}
				fmt.Println(res)
				os.Exit(0)
			case "serve":
				go app.RunPeriodicRefresh(ctx, conf.RefreshInterval)
				app.Register(sm)
			default:
				o.Err(ctx, "start", errors.New("unknown mode"), slog.String("mode", conf.mode))
				os.Exit(1)
			}
			return nil, nil
		},
	})
}
