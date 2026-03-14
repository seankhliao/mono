package run

import (
	"context"
	"flag"
	"io"
	"io/fs"
)

var (
	_ Commander    = &simple{}
	_ CommanderRun = &simple{}
)

type simple struct {
	name string
	desc string
	c    Simpler
}

type Simpler interface {
	Flags(fset *flag.FlagSet, args **[]string) error
	Run(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error
}

func (s *simple) CmdName() string { return s.name }
func (s *simple) CmdDesc() string { return s.desc }

func (s *simple) Flags(fset *flag.FlagSet, args **[]string) error {
	return s.c.Flags(fset, args)
}

func (s *simple) Run(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	return s.c.Run(ctx, stdin, stdout, stderr, fsys)
}

func Simple(name, desc string, c Simpler) CommanderRun {
	return &simple{name, desc, c}
}
