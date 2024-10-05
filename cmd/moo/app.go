package main

import (
	"context"
	"fmt"
	"net/http"

	"go.seankhliao.com/mono/cmd/moo/reqlog"
	"go.seankhliao.com/mono/yrun"
)

type Config struct {
	RegLog reqlog.Config
}

type App struct {
	ReqLog *reqlog.App
}

func New(ctx context.Context, c Config, o yrun.O11y) (a *App, err error) {
	a = &App{}
	a.ReqLog, err = reqlog.New(c.RegLog, o)

	return a, nil
}

func Register(a *App, r yrun.HTTPRegistrar) {
	reqlog.Register(a.ReqLog, r)

	r.Handle("GET", "", "/{$}", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "hello world")
	}))
}
