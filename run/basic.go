package run

import (
	"context"
	"flag"
	"io"
	"io/fs"
	"strings"
)

var _ Commander = &CommandBasic[struct{}]{}

type (
	Empty         = struct{}
	CommandSimple = CommandBasic[Empty]
)

type CommandBasic[C any] struct {
	Name string
	Desc string

	Flags func(c *C, fset *flag.FlagSet) error
	Do    func(c *C) Runner

	conf C
}

func (c *CommandBasic[C]) CmdName() string { return c.Name }
func (c *CommandBasic[C]) ShortDesc() string {
	s, _, _ := strings.Cut(c.Desc, "\n")
	return s
}

func (c *CommandBasic[C]) LongDesc() string {
	return c.Desc
}

func (c *CommandBasic[C]) RegisterFlags(fset *flag.FlagSet) error {
	if c.Flags != nil {
		return c.Flags(&c.conf, fset)
	}
	return nil
}
func (c *CommandBasic[C]) SubCommands() []Commander { return nil }
func (c *CommandBasic[C]) RunCmd(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	return c.Do(&c.conf)(ctx, stdin, stdout, stderr, fsys)
}

func CommandRun(name, desc string, f Runner) *CommandSimple {
	return &CommandSimple{
		Name: name,
		Desc: desc,
		Do: func(c *Empty) Runner {
			return f
		},
	}
}
