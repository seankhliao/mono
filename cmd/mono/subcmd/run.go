package subcmd

import (
	"context"
	"os"
	"os/signal"

	"golang.org/x/sys/unix"
)

func Run(cmds map[string]Runner) {
	ctx := context.Background()
	ctx, cancel := signal.NotifyContext(ctx, unix.SIGINT, unix.SIGTERM)
	defer cancel()

	prog := Prog{
		cmds: cmds,
	}

	os.Exit(prog.Run(ctx, os.Environ(), os.Args, os.DirFS("/"), os.Stdout, os.Stderr))
}
