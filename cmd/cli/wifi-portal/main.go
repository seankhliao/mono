package main

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"io/fs"
	"net/http"

	"go.seankhliao.com/mono/run"
)

func main() {
	run.OSExec(run.Func("wifi-portal", "check the wifi portal login page", f))
}

func f(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	client := &http.Client{CheckRedirect: func(req *http.Request, via []*http.Request) error { return http.ErrUseLastResponse }}
	res, err := client.Get("http://neverssl.com")
	if err != nil {
		return fmt.Errorf("GET neverssl: %w", err)
	}
	b, err := io.ReadAll(res.Body)
	if err != nil {
		return fmt.Errorf("read response body: %w", err)
	}
	if res.StatusCode != 200 || !bytes.Contains(b, []byte("neverssl.com will never use SSL")) {
		loc := res.Header.Get("location")
		if loc != "" {
			fmt.Fprintln(stdout, loc)
			return fmt.Errorf("redirected to %s", loc)
		}
		fmt.Fprintln(stdout, string(b))
		return nil
	}
	fmt.Fprintln(stdout, "ok")
	return nil
}
