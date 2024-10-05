package main

import (
	"go.seankhliao.com/mono/yrun"
)

func main() {
	yrun.Run(yrun.RunConfig[Config, App]{
		New:  New,
		HTTP: Register,
	})
}
