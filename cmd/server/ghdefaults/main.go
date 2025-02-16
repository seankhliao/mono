package main

import (
	"go.seankhliao.com/mono/ghdefaults"
	"go.seankhliao.com/mono/yrun"
)

func main() {
	yrun.Run(yrun.Config[ghdefaults.Config, ghdefaults.App]{
		Config: ghdefaults.Config{
			Host: "ghdefaults.liao.dev",
		},
		New: ghdefaults.New,

		HTTP: ghdefaults.Register,
	})
}
