package main

import (
	"flag"
	"fmt"
	"net/http"
	"os"
	"strings"
)

func main() {
	var addr, dir string
	flag.StringVar(&addr, "addr", ":8739", "address to listen on")
	flag.StringVar(&dir, "dir", ".", "directory to serve")
	flag.Parse()
	if flag.NArg() > 0 {
		fmt.Fprintln(os.Stderr, "unexpected arguments", flag.Args())
		os.Exit(1)
	}

	a := addr
	if strings.HasPrefix(a, ":") {
		a = "127.0.0.1" + a
	}
	a = "http://" + a
	fmt.Fprintln(os.Stdout, "starting on", a)
	http.ListenAndServe(addr, http.FileServer(http.Dir(dir)))
}
