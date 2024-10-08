package main

import (
	"context"
	"fmt"
	"net/http"

	"go.seankhliao.com/mono/cmd/moo/earbug"
	"go.seankhliao.com/mono/cmd/moo/ghdefaults"
	"go.seankhliao.com/mono/cmd/moo/homepage"
	"go.seankhliao.com/mono/cmd/moo/reqlog"
	"go.seankhliao.com/mono/webstyle/webstatic"
	"go.seankhliao.com/mono/yrun"
)

type Config struct {
	Earbug     earbug.Config
	GHDefaults ghdefaults.Config
	Homepage   homepage.Config
	ReqLog     reqlog.Config
}

type App struct {
	Earbug     *earbug.App
	GHDefaults *ghdefaults.App
	Homepage   *homepage.App
	ReqLog     *reqlog.App
}

func New(ctx context.Context, c Config, o yrun.O11y) (a *App, err error) {
	a = &App{}
	a.Earbug, err = earbug.New(c.Earbug, o)
	if err != nil {
		return nil, err
	}
	a.GHDefaults, err = ghdefaults.New(c.GHDefaults, o)
	if err != nil {
		return nil, err
	}
	a.Homepage, err = homepage.New(c.Homepage, o)
	if err != nil {
		return nil, err
	}
	a.ReqLog, err = reqlog.New(c.ReqLog, o)
	if err != nil {
		return nil, err
	}
	return a, nil
}

func Register(a *App, r yrun.HTTPRegistrar) {
	webstatic.Register(r)

	earbug.Register(a.Earbug, r)
	ghdefaults.Register(a.GHDefaults, r)
	homepage.Register(a.Homepage, r)
	reqlog.Register(a.ReqLog, r)

	r.Pattern("GET", "", "/{$}", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "hello world")
	}))
}
