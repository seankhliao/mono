// ycli is a basic
package ycli

import (
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"strconv"
	"strings"
)

func OSExec(c Command) {
	err := c.Exec(os.Args, os.Stdout, os.Stderr)
	if err != nil {
		if !errors.Is(err, flag.ErrHelp) {
			fmt.Fprintln(os.Stderr, err)
		}
		os.Exit(1)
	}
}

type Command struct {
	Name string
	Desc string

	// TODO: figure out how to bind unflagged args
	Flags    *flag.FlagSet
	Commands []Command

	Run func(stdout, stderr io.Writer) error
}

func NewGroup(name, desc string, register func(*flag.FlagSet), cmds ...Command) Command {
	fset := flag.NewFlagSet(name, flag.ContinueOnError)
	register(fset)
	return Command{
		Name:     name,
		Desc:     desc,
		Flags:    fset,
		Commands: cmds,
	}
}

func New(name, desc string, register func(*flag.FlagSet), run func(_, _ io.Writer) error) Command {
	fset := flag.NewFlagSet(name, flag.ContinueOnError)
	register(fset)
	return Command{
		Name:  name,
		Desc:  desc,
		Flags: fset,
		Run:   run,
	}
}

func (c Command) Exec(args []string, stdout, stderr io.Writer) error {
	// remove current command name
	_, args = args[0], args[1:]

	c.Flags.SetOutput(stderr)
	err := c.Flags.Parse(args)
	if err != nil {
		return err
	}
	args = c.Flags.Args()

	// is a command node
	if c.Run != nil {
		if len(args) > 0 {
			// TODO: allow args
			fmt.Fprintln(stderr, "unexpected arguments:", args)
			return c.printHelp(stderr)
		}
		return c.Run(stdout, stderr)
	}

	// has args, try if it's a subcommand
	if len(args) > 0 {
		for _, cmd := range c.Commands {
			if cmd.Name == args[0] {
				c.Flags.VisitAll(func(f *flag.Flag) {
					cmd.Flags.Var(f.Value, f.Name, f.Usage)
				})
				return cmd.Exec(args, stdout, stderr)
			}
		}
	}

	return c.printHelp(stderr)
}

func (c Command) printHelp(output io.Writer) error {
	fmt.Fprintln(output, c.Name)
	fmt.Fprintln(output)
	fmt.Fprintln(output, c.Desc)
	fmt.Fprintln(output)
	if len(c.Commands) > 0 {
		fmt.Fprintln(output, "COMMANDS")
		maxNameLen := len(c.Commands[0].Name)
		for _, cmd := range c.Commands {
			maxNameLen = max(maxNameLen, len(cmd.Name))
		}
		for _, cmd := range c.Commands {
			str := "\t%-" + strconv.Itoa(maxNameLen) + "s\t%s\n"
			desc := strings.Split(cmd.Desc, "\n")
			fmt.Fprintf(output, str, cmd.Name, desc[0])
		}
		fmt.Fprintln(output)
	}
	if c.Flags.NFlag() > 0 {
		fmt.Fprintln(output, "FLAGS")
		c.Flags.PrintDefaults()
	}
	return flag.ErrHelp
}
