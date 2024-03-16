package serve

import (
	"flag"
	"fmt"
	"log/slog"

	"go.seankhliao.com/mono/cmd/mono/ghdefaults"
	"go.seankhliao.com/mono/structflag"
)

type (
	Config struct {
		HTTP ConfigHTTP
		Log  ConfigLog

		GHDefaults ghdefaults.Config
	}

	ConfigHTTP struct {
		Addr string `flag:",http listen address [ip]:port"`
		// Grace int `flag:"grace.seconds"`
	}

	ConfigLog struct {
		Level slog.Level `flag:",log level for application logs"`
	}
)

func NewConfig(env, args []string) (Config, error) {
	var conf Config

	fset := flag.NewFlagSet("mono serve", flag.ContinueOnError)
	err := structflag.RegisterFlags(fset, &conf, "")
	if err != nil {
		return Config{}, fmt.Errorf("register flags: %w", err)
	}
	err = fset.Parse(args)
	if err != nil {
		return Config{}, fmt.Errorf("parse flags: %w", err)
	}

	if conf.HTTP.Addr == "" {
		conf.HTTP.Addr = ":8080"
	}

	return conf, nil
}
