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
	Flags(*flag.FlagSet) error
	Run(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error
}

func (s *simple) CmdName() string { return s.name }
func (s *simple) CmdDesc() string { return s.desc }

func (s *simple) Flags(fset *flag.FlagSet) error {
	return s.c.Flags(fset)
}

func (s *simple) Run(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	return s.c.Run(ctx, stdin, stdout, stderr, fsys)
}

func Simple(name, desc string, c Simpler) Commander {
	return &simple{name, desc, c}
}

func Func(name, desc string, f Runner) Commander {
	return &simpleFunc{name, desc, f}
}

type simpleFunc struct {
	name string
	desc string
	f    Runner
}

func (s *simpleFunc) CmdName() string           { return s.name }
func (s *simpleFunc) CmdDesc() string           { return s.desc }
func (s *simpleFunc) Flags(*flag.FlagSet) error { return nil }
func (s *simpleFunc) Run(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	return s.f(ctx, stdin, stdout, stderr, fsys)
}
