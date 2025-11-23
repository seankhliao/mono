package cueconf

import (
	"errors"
	"fmt"
	"io/fs"
	"os"

	"cuelang.org/go/cue"
	"cuelang.org/go/cue/cuecontext"
)

func ForBytes[T any](schema, spec string, config []byte) (conf T, err error) {
	p := cue.ParsePath("out")
	ctx := cuecontext.New()
	val := ctx.CompileString(schema)
	val = val.FillPath(p, val.LookupPath(cue.MakePath(cue.Def(spec))))
	val = val.FillPath(p, ctx.CompileBytes(config))
	val = val.LookupPath(p)
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

func ForFile[T any](schema, spec, fpath string, optional bool) (conf T, err error) {
	b, err := os.ReadFile(fpath)
	if err != nil && !(optional && errors.Is(err, fs.ErrNotExist)) {
		return conf, fmt.Errorf("read config file: %w", err)
	}
	return ForBytes[T](schema, spec, b)
}
