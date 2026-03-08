package main

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"io/fs"
	"os/exec"
	"time"

	"go.seankhliao.com/mono/run"
)

func main() {
	run.OSExec(run.CommandRun(
		"lapis",
		"connect to lapis wifi",
		func(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) int {
			b, err := exec.CommandContext(ctx, "iwctl", "station", "wlan0", "scan").CombinedOutput()
			if err != nil {
				fmt.Fprintln(stderr, "scan", string(b))
				return 1
			}
			for range 10 {
				b, err = exec.CommandContext(ctx, "iwctl", "station", "wlan0", "get-networks").CombinedOutput()
				if err != nil {
					fmt.Fprintln(stderr, "get-networks:", string(b))
					time.Sleep(time.Second)
					continue
				}
				if !bytes.Contains(b, []byte("lapis")) {
					fmt.Fprintln(stdout, "lapis not in networks, sleeping...")
					time.Sleep(time.Second)
					continue
				}
				break
			}
			b, err = exec.CommandContext(ctx, "iwctl", "station", "wlan0", "connect", "lapis").CombinedOutput()
			if err != nil {
				fmt.Fprintln(stderr, "connect", string(b))
				return 1
			}
			return 0
		}),
	)
}
