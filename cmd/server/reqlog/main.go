package main

import (
	"context"

	"go.seankhliao.com/mono/reqlog"
	"go.seankhliao.com/mono/yo11y"
	"go.seankhliao.com/mono/yrun"
	"gocloud.dev/blob"
)

func main() {
	yrun.Run(yrun.Config[reqlog.Config, reqlog.App]{
		Config: reqlog.Config{
			Host: "reqlog.liao.dev",
		},
		New: func(ctx context.Context, c reqlog.Config, b *blob.Bucket, o yo11y.O11y) (*reqlog.App, error) {
			return reqlog.New(c, o)
		},

		HTTP: reqlog.Register,
	})
}
