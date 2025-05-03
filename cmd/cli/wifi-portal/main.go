package main

import (
	"bytes"
	"fmt"
	"io"
	"net/http"
	"os"
)

func main() {
	client := &http.Client{
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			return http.ErrUseLastResponse
		},
	}
	res, err := client.Get("http://neverssl.com")
	if err != nil {
		fmt.Fprintln(os.Stderr, "GET", err)
		os.Exit(1)
	}
	b, err := io.ReadAll(res.Body)
	if err != nil {
		fmt.Fprintln(os.Stderr, "read response body", err)
		os.Exit(1)
	}

	if res.StatusCode == 200 && bytes.Contains(b, []byte("neverssl.com will never use SSL")) {
		fmt.Println("ok")
		os.Exit(0)
	}

	loc := res.Header.Get("location")
	if loc != "" {
		fmt.Println(loc)
		os.Exit(1)
	}
	fmt.Println(string(b))
}
