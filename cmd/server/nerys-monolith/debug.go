package main

import (
	"fmt"
	"net/http"
	"net/http/pprof"
	"runtime/debug"
)

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
