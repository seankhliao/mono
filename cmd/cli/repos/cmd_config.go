package main

import (
	"context"
	_ "embed"
	"fmt"
	"io"
	"io/fs"

	"go.seankhliao.com/mono/cmdline"
)

//go:embed wrapper.zsh
var shellWrapper string

func cmdConfig(conf *CommonConfig) cmdline.Commander {
	return cmdline.CommandRun(
		"config",
		"print the config",
		func(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) int {
			fmt.Fprintln(stdout, shellWrapper)
			return 0
		},
	)
}
