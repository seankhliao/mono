package main

import (
	"context"
	_ "embed"
	"fmt"
	"io"
	"io/fs"

	"go.seankhliao.com/mono/run"
)

//go:embed wrapper.zsh
var shellWrapper string

func cmdConfig(conf *CommonConfig) run.Commander {
	return run.CommandRun(
		"config",
		"print the config",
		func(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
			fmt.Fprintln(stdout, shellWrapper)
			return nil
		},
	)
}
