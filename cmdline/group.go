package cmdline

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

	Subs []Commander
}

func (c *CommandGroup) CmdName() string { return c.Name }
func (c *CommandGroup) ShortDesc() string {
	s, _, _ := strings.Cut(c.Desc, "\n")
	return s
}

func (c *CommandGroup) LongDesc() string {
	return c.Desc
}

func (c *CommandGroup) RegisterFlags(fset *flag.FlagSet) {}
func (c *CommandGroup) SubCommands() []Commander         { return c.Subs }
func (c *CommandGroup) RunCmd(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) int {
	return -1
}
