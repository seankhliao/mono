package main

import (
	"context"
	"fmt"
	"net/http"

	"go.seankhliao.com/mono/cmd/moo/homepage"
	"go.seankhliao.com/mono/cmd/moo/reqlog"
	"go.seankhliao.com/mono/webstyle/webstatic"
	"go.seankhliao.com/mono/yrun"
)

type Config struct {
	ReqLog   reqlog.Config
	Homepage homepage.Config
}

type App struct {
	ReqLog   *reqlog.App
	Homepage *homepage.App
}

func New(ctx context.Context, c Config, o yrun.O11y) (a *App, err error) {
	a = &App{}
	a.ReqLog, err = reqlog.New(c.ReqLog, o)
	a.Homepage, err = homepage.New(c.Homepage, o)

	return a, nil
}

func Register(a *App, r yrun.HTTPRegistrar) {
	webstatic.Register(r)

	reqlog.Register(a.ReqLog, r)
	homepage.Register(a.Homepage, r)

	r.Pattern("GET", "", "/{$}", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "hello world")
	}))
}
