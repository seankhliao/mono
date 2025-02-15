package main

import (
	"context"

	"go.seankhliao.com/mono/goproxyaudit"
	"go.seankhliao.com/mono/yo11y"
	"go.seankhliao.com/mono/yrun"
	"gocloud.dev/blob"
)

func main() {
	yrun.Run(yrun.Config[goproxyaudit.Config, goproxyaudit.App]{
		Config: goproxyaudit.Config{
			Host: "goproxyaudit.liao.dev",
		},
		New: func(ctx context.Context, c goproxyaudit.Config, b *blob.Bucket, o yo11y.O11y) (*goproxyaudit.App, error) {
			return goproxyaudit.New(ctx, c, b, o)
		},

		HTTP:       goproxyaudit.Register,
		Background: goproxyaudit.Background,
		Shutdown:   goproxyaudit.Shutdown,
	})
}
