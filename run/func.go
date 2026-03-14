package run

import (
	"context"
	"flag"
	"io"
	"io/fs"
)

var (
	_ Commander    = &simpleFunc{}
	_ CommanderRun = &simpleFunc{}
)

type simpleFunc struct {
	name string
	desc string
	f    Runner
}

func (s *simpleFunc) CmdName() string                       { return s.name }
func (s *simpleFunc) CmdDesc() string                       { return s.desc }
func (s *simpleFunc) Flags(*flag.FlagSet, **[]string) error { return nil }
func (s *simpleFunc) Run(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	return s.f(ctx, stdin, stdout, stderr, fsys)
}

func Func(name, desc string, f Runner) Commander {
	return &simpleFunc{name, desc, f}
}
