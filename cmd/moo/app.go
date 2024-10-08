package main

import (
	"context"
	"fmt"
	"net/http"

	"go.seankhliao.com/mono/cmd/moo/ghdefaults"
	"go.seankhliao.com/mono/cmd/moo/homepage"
	"go.seankhliao.com/mono/cmd/moo/reqlog"
	"go.seankhliao.com/mono/webstyle/webstatic"
	"go.seankhliao.com/mono/yrun"
)

type Config struct {
	GHDefaults ghdefaults.Config
	Homepage   homepage.Config
	ReqLog     reqlog.Config
}

type App struct {
	GHDefaults *ghdefaults.App
	Homepage   *homepage.App
	ReqLog     *reqlog.App
}

func New(ctx context.Context, c Config, o yrun.O11y) (a *App, err error) {
	a = &App{}
	a.GHDefaults, err = ghdefaults.New(c.GHDefaults, o)
	a.Homepage, err = homepage.New(c.Homepage, o)
	a.ReqLog, err = reqlog.New(c.ReqLog, o)
	return a, nil
}

func Register(a *App, r yrun.HTTPRegistrar) {
	webstatic.Register(r)

	ghdefaults.Register(a.GHDefaults, r)
	homepage.Register(a.Homepage, r)
	reqlog.Register(a.ReqLog, r)

	r.Pattern("GET", "", "/{$}", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "hello world")
	}))
}
