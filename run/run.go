// Package run provides some basic tools for registering commands
// with configs and running them.
package run

import (
	"context"
	"encoding/csv"
	"errors"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
)

// Commander represents a process command or subcommand
type Commander interface {
	CmdName() string
	ShortDesc() string
	LongDesc() string

	RegisterFlags(*flag.FlagSet) error
	SubCommands() []Commander
	RunCmd(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error
}

type Runner func(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error

// OSExec runs the given [Commander] with the default arguments
// to interact with the os:
//
//	func main() {
//		cmdline.OSExec(c)
//	}
func OSExec(c Commander) {
	os.Exit(Exec(c, os.Args, os.Stdin, os.Stdout, os.Stderr, os.DirFS("/")))
}

// Exec runs the given command, allowing injection of most OS parameters.
func Exec(c Commander, args []string, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) int {
	run := findRun(nil, c, args)
	ctx := context.Background()
	err := run(ctx, stdin, stdout, stderr, fsys)
	if err != nil {
		fmt.Fprintln(stderr, err)
		return 1
	}
	return 0
}

func findRun(parents []string, c Commander, args []string) Runner {
	fset := flag.NewFlagSet(c.CmdName(), flag.ContinueOnError)
	fset.Usage = func() {}
	fset.SetOutput(io.Discard)

	var debugPrintFlags bool
	fset.BoolVar(&debugPrintFlags, "flag-debug", false, "print the resolved flag values")
	var extraArgs []string
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
			extraArgs = append(extraArgs, asr...)
		}
		return nil
	})
	fset.Func("flag-env", `read flags from the given env var, may use "quoted values"`, func(s string) error {
		val := os.Getenv(s)
		cr := csv.NewReader(strings.NewReader(val))
		cr.Comma = ' '
		cr.FieldsPerRecord = -1
		as, err := cr.ReadAll()
		if err != nil {
			return fmt.Errorf("read from env %s: %w", s, err)
		}
		for _, asr := range as {
			extraArgs = append(extraArgs, asr...)
		}
		return nil
	})

	c.RegisterFlags(fset)

	err := fset.Parse(args[1:])
	if errors.Is(err, flag.ErrHelp) {
		return helpFor(c, parents, fset, nil)
	} else if err != nil {
		return helpFor(c, parents, fset, err)
	}
	if len(extraArgs) > 0 {
		err = fset.Parse(extraArgs)
		if errors.Is(err, flag.ErrHelp) {
			return helpFor(c, parents, fset, nil)
		} else if err != nil {
			return helpFor(c, parents, fset, err)
		}
	}

	if fset.NArg() == 0 {
		_, ok := c.(*CommandGroup)
		if ok {
			return helpFor(c, parents, fset, errors.New("no command given"))
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

	return helpFor(c, parents, fset, fmt.Errorf("unexpected arguments: %v", fset.Args()))
}

func helpFor(c Commander, parents []string, fset *flag.FlagSet, err error) Runner {
	return func(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
		w := stdout
		if err != nil {
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

		return err
	}
}

func printDebugFlags(fset *flag.FlagSet) Runner {
	return func(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
		fset.VisitAll(func(f *flag.Flag) {
			fmt.Fprintf(stdout, "-%s=%v ", f.Name, f.Value)
		})

		return nil
	}
}

func UserConfigFile(fset *flag.FlagSet, name string, required bool) error {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return fmt.Errorf("get home dir: %w", err)
	}
	confDir := filepath.Join(homeDir, ".config")
	confFile := filepath.Join(confDir, name)
	if !required {
		_, err := os.Stat(confFile)
		if err != nil {
			return nil
		}
	}
	fset.Set("flag-file", confFile)
	return nil
}

func ChdirToParentFlagFile(fset *flag.FlagSet, name string) error {
	for {
		_, err := os.Stat(name)
		if err == nil {
			break
		} else if !errors.Is(err, os.ErrNotExist) {
			return fmt.Errorf("error checking for config file: %w", err)
		}

		_, err = os.Stat(".git")
		if err == nil {
			return fmt.Errorf("config file not found, not checking past repo root")
		} else if !errors.Is(err, os.ErrNotExist) {
			return fmt.Errorf("error checking for git root: %w", err)
		}
		_, err = os.Stat(".jj")
		if err == nil {
			return fmt.Errorf("config file not found, not checking past repo root")
		} else if !errors.Is(err, os.ErrNotExist) {
			return fmt.Errorf("error checking for git root: %w", err)
		}

		if dir, _ := os.Getwd(); dir == "/" {
			return fmt.Errorf("at system root /, config file not found")
		}
		err = os.Chdir("..")
		if err != nil {
			return fmt.Errorf("chdir to parent: %w", err)
		}
	}

	err := fset.Set("flag-file", name)
	if err != nil {
		return fmt.Errorf("set flag-file: %w", err)
	}
	return nil
}
