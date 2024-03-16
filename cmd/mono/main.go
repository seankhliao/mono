package main

import (
	"go.seankhliao.com/mono/cmd/mono/serve"
	"go.seankhliao.com/mono/cmd/mono/subcmd"
	"go.uber.org/automaxprocs/maxprocs"
)

func main() {
	maxprocs.Set()
	subcmd.Run(map[string]subcmd.Runner{
		"serve": serve.Run,
	})
}
