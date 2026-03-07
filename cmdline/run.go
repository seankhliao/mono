// Package cmdline provides some basic tools for registering commands
// with configs and running them.
package cmdline

import (
	"context"
	"encoding/csv"
	"errors"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"os"
	"strings"
)

// Commander represents a process command or subcommand
type Commander interface {
	CmdName() string
	ShortDesc() string
	LongDesc() string

	RegisterFlags(*flag.FlagSet)
	SubCommands() []Commander
	RunCmd(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) int
}

type Runner = func(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) int

// RunOS runs the given [Commander] with the default arguments
// to interact with the os:
//
//	func main() {
//		cmdline.RunOS(c)
//	}
func RunOS(c Commander) {
	os.Exit(Run(c, os.Args, os.Stdin, os.Stderr, os.Stdout, os.DirFS("/")))
}

// Run runs the given command, allowing injection of most OS parameters.
func Run(c Commander, args []string, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) int {
	run := findRun(nil, c, args)
	ctx := context.Background()
	return run(ctx, stdin, stdout, stderr, fsys)
}

func findRun(parents []string, c Commander, args []string) Runner {
	fset := flag.NewFlagSet(c.CmdName(), flag.ContinueOnError)
	fset.Usage = func() {}
	fset.SetOutput(io.Discard)

	var debugPrintFlags bool
	fset.BoolVar(&debugPrintFlags, "flag-debug", false, "print the resolved flag values")
	var argsFromFiles []string
	fset.Func("flag-file", `read flags from the given file. overrides cmdline flags, may use "quoted values"`, func(s string) error {
		f, err := os.Open(s)
		if err != nil {
			return fmt.Errorf("read file %s: %w", s, err)
		}
		defer f.Close()
		cr := csv.NewReader(f)
		cr.Comma = ' '
		cr.FieldsPerRecord = -1
		as, err := cr.ReadAll()
		if err != nil {
			return fmt.Errorf("read args from file %s: %w", s, err)
		}
		for _, asr := range as {
			argsFromFiles = append(argsFromFiles, asr...)
		}
		return nil
	})

	c.RegisterFlags(fset)

	err := fset.Parse(args[1:])
	if errors.Is(err, flag.ErrHelp) {
		return helpFor(c, parents, fset, 0)
	} else if err != nil {
		return func(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) int {
			fmt.Fprintf(stderr, "parse cmdline: %v\n\n", err)
			return helpFor(c, parents, fset, 1)(ctx, stdin, stdout, stderr, fsys)
		}
	}
	if len(argsFromFiles) > 0 {
		err = fset.Parse(argsFromFiles)
		if errors.Is(err, flag.ErrHelp) {
			return helpFor(c, parents, fset, 0)
		} else if err != nil {
			return func(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) int {
				fmt.Fprintf(stderr, "parse args from files: %v\n\n", err)
				return helpFor(c, parents, fset, 1)(ctx, stdin, stdout, stderr, fsys)
			}
		}
	}

	if fset.NArg() == 0 {
		_, ok := c.(*CommandGroup)
		if ok {
			return helpFor(c, parents, fset, 1)
		}

		if debugPrintFlags {
			return printDebugFlags(fset)
		}

		return c.RunCmd
	}
	subName := fset.Arg(0)
	for _, sub := range c.SubCommands() {
		if subName == sub.CmdName() {
			return findRun(append(parents, c.CmdName()), sub, fset.Args())
		}
	}

	return func(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) int {
		fmt.Fprintf(stderr, "unexpected arguments: %v\n\n", fset.Args())
		return helpFor(c, parents, fset, 1)(ctx, stdin, stdout, stderr, fsys)
	}
}

func helpFor(c Commander, parents []string, fset *flag.FlagSet, exit int) Runner {
	return func(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) int {
		w := stdout
		if exit != 0 {
			w = stderr
		}

		fmt.Fprintf(w, "Usage: %s [flags]\n", strings.Join(append(parents, c.CmdName()), " "))

		fmt.Fprintf(w, "\n%s\n", c.LongDesc())

		subs := c.SubCommands()
		if len(subs) > 0 {
			fmt.Fprintf(w, "\nCommands:\n")
			for _, sub := range subs {
				fmt.Fprintf(w, "\t%s\n\t\t%s\n", sub.CmdName(), sub.ShortDesc())
			}
		}

		fmt.Fprintf(w, "\nFlags:\n")
		fset.VisitAll(func(f *flag.Flag) {
			fmt.Fprintf(w, "\t-%s\n", f.Name)
			if f.DefValue != "" {
				fmt.Fprintf(w, "\t\tdefault: %v\n", f.Value)
			}
			fmt.Fprintf(w, "\t\t%s\n", f.Usage)
		})
		return exit
	}
}

func printDebugFlags(fset *flag.FlagSet) Runner {
	return func(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) int {
		fset.VisitAll(func(f *flag.Flag) {
			fmt.Fprintf(stdout, "-%s %v", f.Name, f.Value)
		})

		return 0
	}
}
