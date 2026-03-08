package run

import (
	"context"
	"flag"
	"io"
	"io/fs"
	"strings"
)

var _ Commander = &CommandGroup{}

type CommandGroup struct {
	Name string
	Desc string

	Flags func(fset *flag.FlagSet) error
	Subs  []Commander
}

func (c *CommandGroup) CmdName() string { return c.Name }
func (c *CommandGroup) ShortDesc() string {
	s, _, _ := strings.Cut(c.Desc, "\n")
	return s
}

func (c *CommandGroup) LongDesc() string {
	return c.Desc
}

func (c *CommandGroup) RegisterFlags(fset *flag.FlagSet) error {
	if c.Flags != nil {
		return c.Flags(fset)
	}
	return nil
}
func (c *CommandGroup) SubCommands() []Commander { return c.Subs }
func (c *CommandGroup) RunCmd(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	return nil
}
