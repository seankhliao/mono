package main

import (
	"context"
	"fmt"
	"net/http"
)

type Config struct{}

type App struct{}

func New(ctx context.Context, c Config) (*App, error) {
	a := &App{}
	return a, nil
}

func (a *App) RegisterHTTP(sm *http.ServeMux) {
	mux := muxRegister{sm}
	mux.Handle("GET", "", "/{$}", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "hello world")
	}))
}

type muxRegister struct {
	mux *http.ServeMux
}

func (r *muxRegister) Handle(method, host, pattern string, handler http.Handler) {
	r.mux.Handle(method+" "+host+" "+pattern, handler)
}
