package cmdline

import (
	"context"
	"flag"
	"io"
	"io/fs"
	"strings"
)

var _ Commander = &CommandBasic[struct{}]{}

type CommandBasic[C any] struct {
	Name string
	Desc string

	Flags func(c *C, fset *flag.FlagSet)
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

func (c *CommandBasic[C]) RegisterFlags(fset *flag.FlagSet) {
	if c.Flags != nil {
		c.Flags(&c.conf, fset)
	}
}
func (c *CommandBasic[C]) SubCommands() []Commander { return nil }
func (c *CommandBasic[C]) RunCmd(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) int {
	return c.Do(&c.conf)(ctx, stdin, stdout, stderr, fsys)
}
