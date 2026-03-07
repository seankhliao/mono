package main

import (
	"context"
	"fmt"
	"net/http"
	"net/http/httputil"
	"os"

	"go.seankhliao.com/mono/yhttp"
	"go.seankhliao.com/mono/yo11y"
	"go.seankhliao.com/mono/yrun"
)

type (
	Config struct{}
	App    struct{}
)

func main() {
	os.Exit(yrun.Run(yrun.Config[Config, App]{
		New: func(ctx context.Context, c Config, o yo11y.O11y) (*App, error) { return &App{}, nil },
		HTTP: func(a *App, r yhttp.Registrar) {
			r.Handle("/", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				fmt.Fprintf(w, "%+v\n", r)
				b, _ := httputil.DumpRequest(r, true)
				fmt.Fprintf(w, "============\n%s", string(b))
			}))
		},
	}))
}
