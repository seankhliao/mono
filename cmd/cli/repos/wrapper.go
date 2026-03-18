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

type Wrapper struct {
	evalFile string
}

func (c *Wrapper) Flags(fset *flag.FlagSet, args **[]string) error {
	fset.StringVar(&c.evalFile, "eval-file", "", "path to a file to output commands to eval")
	return nil
}

func (c *Wrapper) Run(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	fmt.Fprintln(stdout, shellWrapper)
	return nil
}
