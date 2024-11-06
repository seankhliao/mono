package main

import (
	"context"
	_ "embed"
	"fmt"
	"net/http"

	"go.seankhliao.com/mono/cmd/moo/auth"
	"go.seankhliao.com/mono/cmd/moo/earbug"
	"go.seankhliao.com/mono/cmd/moo/ghdefaults"
	"go.seankhliao.com/mono/cmd/moo/homepage"
	"go.seankhliao.com/mono/cmd/moo/reqlog"
	"go.seankhliao.com/mono/cmd/moo/ulist"
	"go.seankhliao.com/mono/webstyle/webstatic"
	"go.seankhliao.com/mono/yrun"
	"gocloud.dev/blob"
)

func main() {
	yrun.Run(yrun.RunConfig[Config, App]{
		AppConfigSchema: schema,
		New:             New,
		HTTP:            Register,
		StartTasks:      StartTasks,
		Debug:           Debug,
	})
}

//go:embed config.cue
var schema string

type Config struct {
	Auth       auth.Config
	Earbug     earbug.Config
	GHDefaults ghdefaults.Config
	Homepage   homepage.Config
	ReqLog     reqlog.Config
	Ulist      ulist.Config
}

type App struct {
	Auth       *auth.App
	Earbug     *earbug.App
	GHDefaults *ghdefaults.App
	Homepage   *homepage.App
	ReqLog     *reqlog.App
	Ulist      *ulist.App
}

func New(ctx context.Context, c Config, bkt *blob.Bucket, o yrun.O11y) (a *App, err error) {
	a = &App{}

	a.Auth, err = auth.New(c.Auth, bkt, o)
	if err != nil {
		return nil, err
	}

	a.Earbug, err = earbug.New(c.Earbug, bkt, o)
	if err != nil {
		return nil, err
	}
	a.Earbug.AuthN = a.Auth.AuthN
	a.Earbug.AuthZ = a.Auth.AuthZ

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

	a.Ulist, err = ulist.New(c.Ulist, bkt, o)
	if err != nil {
		return nil, err
	}
	a.Ulist.AuthN = a.Auth.AuthN
	a.Ulist.AuthZ = a.Auth.AuthZ

	return a, nil
}

func Register(a *App, r yrun.HTTPRegistrar) {
	webstatic.Register(r)

	auth.Register(a.Auth, r)
	earbug.Register(a.Earbug, r)
	ghdefaults.Register(a.GHDefaults, r)
	homepage.Register(a.Homepage, r)
	reqlog.Register(a.ReqLog, r)
	ulist.Register(a.Ulist, r)

	r.Pattern("GET", "", "/{$}", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "hello world")
	}))
}

func Debug(a *App, r yrun.HTTPRegistrar) {
	auth.Admin(a.Auth, r)
}

func StartTasks(a *App, ctx context.Context, start func(func() error)) {
	start(a.Earbug.Update)
}
