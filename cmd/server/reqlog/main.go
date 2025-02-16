package main

import (
	"go.seankhliao.com/mono/reqlog"
	"go.seankhliao.com/mono/yrun"
)

func main() {
	yrun.Run(yrun.Config[reqlog.Config, reqlog.App]{
		Config: reqlog.Config{
			Host: "reqlog.liao.dev",
		},
		New: reqlog.New,

		HTTP: reqlog.Register,
	})
}
