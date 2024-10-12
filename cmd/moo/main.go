package main

import (
	"go.seankhliao.com/mono/yrun"
)

func main() {
	yrun.Run(yrun.RunConfig[Config, App]{
		Config: yrun.FromBucket[Config]("gs://config-liao-dev", "moo.cue"),
		New:    New,
		HTTP:   Register,
		Debug:  Debug,
	})
}
