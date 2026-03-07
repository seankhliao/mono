package main

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"io/fs"
	"net/http"

	"go.seankhliao.com/mono/cmdline"
)

func main() {
	cmdline.RunOS(cmdline.CommandRun(
		"wifi-portal",
		"check the wifi portal login page",
		func(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) int {
			client := &http.Client{
				CheckRedirect: func(req *http.Request, via []*http.Request) error {
					return http.ErrUseLastResponse
				},
			}
			res, err := client.Get("http://neverssl.com")
			if err != nil {
				fmt.Fprintln(stderr, "GET neverssl", err)
				return 1
			}
			b, err := io.ReadAll(res.Body)
			if err != nil {
				fmt.Fprintln(stderr, "read response body", err)
				return 1
			}

			if res.StatusCode != 200 || !bytes.Contains(b, []byte("neverssl.com will never use SSL")) {
				loc := res.Header.Get("location")
				if loc != "" {
					fmt.Fprintln(stdout, loc)
					return 1
				}
				fmt.Fprintln(stdout, string(b))
				return 0
			}
			fmt.Fprintln(stdout, "ok")
			return 0
		}))
}
