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
	var printSchema bool
	var printScript bool
	return ycli.New(
		"config",
		"print the config",
		func(fs *flag.FlagSet) {
			fs.BoolVar(&printScript, "script", false, "print the zsh wrapper script")
			fs.BoolVar(&printSchema, "schema", false, "show the default instead of resolved config")
		},
		func(stdout, stderr io.Writer) error {
			if printScript {
				fmt.Fprintln(stdout, shellWrapper)
				return nil
			}
			_, configVal := conf.defaultConfig()
			if !printSchema {
				var err error
				configVal, err = conf.resolvedConfig()
				if err != nil {
					return err
				}
			}

			fmt.Fprintln(stdout, configVal)
			return nil
		},
	)
}
