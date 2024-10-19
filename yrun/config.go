package yrun

import (
	_ "embed"
	"fmt"

	"cuelang.org/go/cue"
	"cuelang.org/go/cue/cuecontext"
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
