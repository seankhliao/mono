package main

import (
	"context"

	"go.seankhliao.com/mono/ghdefaults"
	"go.seankhliao.com/mono/yo11y"
	"go.seankhliao.com/mono/yrun"
	"gocloud.dev/blob"
)

func main() {
	yrun.Run(yrun.Config[ghdefaults.Config, ghdefaults.App]{
		Config: ghdefaults.Config{
			Host: "ghdefaults.liao.dev",
		},
		New: func(ctx context.Context, c ghdefaults.Config, b *blob.Bucket, o yo11y.O11y) (*ghdefaults.App, error) {
			return ghdefaults.New(c, o)
		},

		HTTP: ghdefaults.Register,
	})
}
