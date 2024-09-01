package cueconf

import (
	"fmt"
	"os"

	"cuelang.org/go/cue"
	"cuelang.org/go/cue/cuecontext"
)

func ForBytes[T any](schema string, config []byte) (conf T, err error) {
	ctx := cuecontext.New()
	val := ctx.CompileString(schema)
	val = val.Unify(ctx.CompileBytes(config))

	err = val.Validate(cue.Final(), cue.Concrete(true))
	if err != nil {
		return conf, fmt.Errorf("validate config: %w", err)
	}

	err = val.Decode(&conf)
	if err != nil {
		return conf, fmt.Errorf("decode config: %w", err)
	}

	return conf, nil
}

func ForFile[T any](schema, fpath string) (conf T, err error) {
	b, err := os.ReadFile(fpath)
	if err != nil {
		return conf, fmt.Errorf("read config file: %w", err)
	}
	return ForBytes[T](schema, b)
}
