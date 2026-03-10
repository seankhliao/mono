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
	run.OSExec(run.Func("lapis", "connect to lapis wifi", f))
}

func f(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	b, err := exec.CommandContext(ctx, "iwctl", "station", "wlan0", "scan").CombinedOutput()
	if err != nil {
		return fmt.Errorf("scan: %s, %w", string(b), err)
	}
	for range 10 {
		b, err = exec.CommandContext(ctx, "iwctl", "station", "wlan0", "get-networks").CombinedOutput()
		if err != nil {
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
		return fmt.Errorf("connect: %s, %w", string(b), err)
	}
	return nil
}
