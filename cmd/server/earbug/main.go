package main

import (
	"context"
	"time"

	"go.seankhliao.com/mono/earbug"
	"go.seankhliao.com/mono/yo11y"
	"go.seankhliao.com/mono/yrun"
	"gocloud.dev/blob"
)

func main() {
	yrun.Run(yrun.Config[earbug.Config, earbug.App]{
		Config: earbug.Config{
			Host:       "earbug.liao.dev",
			UpdateFreq: 5 * time.Minute,
		},
		New: func(ctx context.Context, c earbug.Config, b *blob.Bucket, o yo11y.O11y) (*earbug.App, error) {
			return earbug.New(c, b, o)
		},

		HTTP:       earbug.Register,
		Background: earbug.Background,
	})
}
