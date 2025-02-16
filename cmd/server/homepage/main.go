package main

import (
	"go.seankhliao.com/mono/homepage"
	"go.seankhliao.com/mono/yrun"
)

func main() {
	yrun.Run(yrun.Config[homepage.Config, homepage.App]{
		Config: homepage.Config{
			Host: "justia.liao.dev",
		},
		New: homepage.New,

		HTTP: homepage.Register,
	})
}
