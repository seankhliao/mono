package main

import (
	_ "embed"
	"flag"
	"fmt"
	"io"

	"go.seankhliao.com/mono/ycli"
)

//go:embed wrapper.zsh
var shellWrapper string

func cmdConfig(conf *CommonConfig) ycli.Command {
	return ycli.New(
		"config",
		"print the config",
		func(fs *flag.FlagSet) {},
		func(stdout, stderr io.Writer) error {
			fmt.Fprintln(stdout, shellWrapper)
			return nil
		},
	)
}
