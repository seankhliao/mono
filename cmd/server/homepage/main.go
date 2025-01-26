package main

import (
	"context"

	"go.seankhliao.com/mono/homepage"
	"go.seankhliao.com/mono/yo11y"
	"go.seankhliao.com/mono/yrun"
	"gocloud.dev/blob"
)

func main() {
	yrun.Run(yrun.Config[homepage.Config, homepage.App]{
		Config: homepage.Config{
			Host: "justia.liao.dev",
		},
		New: func(ctx context.Context, c homepage.Config, b *blob.Bucket, o yo11y.O11y) (*homepage.App, error) {
			return homepage.New(c, o)
		},

		HTTP: homepage.Register,
	})
}
