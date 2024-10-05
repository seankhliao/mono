package yrun

import (
	"context"
	_ "embed"
	"fmt"

	"cuelang.org/go/cue"
	"cuelang.org/go/cue/cuecontext"
	"gocloud.dev/blob"
	_ "gocloud.dev/blob/fileblob"
	_ "gocloud.dev/blob/gcsblob"
)

//go:embed config.cue
var baseSchema string

// Config is the base config type for all applications.
// It carries common config, and embeds application
// specific config
type Config[AppConfig any] struct {
	O11y  O11yConfig
	HTTP  HTTPConfig
	Debug HTTPConfig
	GRPC  gRPCConfig
	App   AppConfig
}

func defaultConfig[AppConfig any](ctx context.Context) (Config[AppConfig], error) {
	return FromBytes[Config[AppConfig]](baseSchema, nil)
}

// FromBucket
func FromBucket[AppConfig any](bucket, path string) func(context.Context) (Config[AppConfig], error) {
	return func(ctx context.Context) (c Config[AppConfig], err error) {
		bkt, err := blob.OpenBucket(ctx, bucket)
		if err != nil {
			return c, fmt.Errorf("open bucket %q: %w", bucket, err)
		}
		confBytes, err := bkt.ReadAll(ctx, path)
		if err != nil {
			return c, fmt.Errorf("read conf file from %q %q: %w", bucket, path, err)
		}

		c, err = FromBytes[Config[AppConfig]](baseSchema, confBytes)
		if err != nil {
			return c, fmt.Errorf("parse config: %w", err)
		}
		return c, nil
	}
}

func FromBytes[T any](schema string, config []byte) (conf T, err error) {
	ctx := cuecontext.New()
	val := ctx.CompileString(schema)
	val = val.Unify(ctx.CompileBytes(config))

	err = val.Validate(cue.Final())
	if err != nil {
		return conf, fmt.Errorf("validate config: %w", err)
	}

	err = val.Decode(&conf)
	if err != nil {
		return conf, fmt.Errorf("decode config: %w", err)
	}

	return conf, nil
}
