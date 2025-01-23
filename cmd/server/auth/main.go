package main

import (
	"context"

	"go.seankhliao.com/mono/auth"
	"go.seankhliao.com/mono/yo11y"
	"go.seankhliao.com/mono/yrun"
	"gocloud.dev/blob"
)

func main() {
	yrun.Run(yrun.Config[auth.Config, auth.App]{
		Config: auth.Config{
			Host:         "auth.liao.dev",
			CookieDomain: "liao.dev",
			CookieName:   "__mono_auth",
		},
		New: func(ctx context.Context, c auth.Config, b *blob.Bucket, o yo11y.O11y) (*auth.App, error) {
			return auth.New(c, b, o)
		},
		HTTP:  auth.Register,
		Debug: auth.Admin,

		Background: func(a *auth.App) []func(context.Context) error {
			return []func(context.Context) error{
				func(ctx context.Context) error { return a.CleanSessions() },
			}
		},
	})
}
