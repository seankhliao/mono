package main

import (
	"context"
	_ "embed"
	"flag"
	"fmt"
	"io"
	"io/fs"
)

//go:embed wrapper.zsh
var shellWrapper string

type configCmd struct{}

func (c *configCmd) Flags(fset *flag.FlagSet, args **[]string) error { return nil }

func (c *configCmd) Run(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	fmt.Fprintln(stdout, shellWrapper)
	return nil
}
