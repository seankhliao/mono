package subcmd

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"path/filepath"
	"slices"
	"strings"
)

type Runner func(ctx context.Context, envs, args []string, fsys fs.FS, stdout, stderr io.Writer) error

type Prog struct {
	cmds map[string]Runner
}

func (p *Prog) Subcmd(name string, runner Runner) {
	if p.cmds == nil {
		p.cmds = make(map[string]Runner)
	}
	p.cmds[name] = runner
}

func (p *Prog) Run(ctx context.Context, env, args []string, fsys fs.FS, stdout, stderr io.Writer) int {
	// program name
	prog, args := args[0], args[1:]

	// subcommand name
	if len(args) == 0 || strings.HasPrefix(args[0], "-") {
		printKnownSubcommands(stderr, prog, p.cmds)
		return 1
	}
	subcmd, args := args[0], args[1:]

	runner, ok := p.cmds[subcmd]
	if !ok {
		printKnownSubcommands(stderr, prog, p.cmds)
		return 1
	}

	err := runner(ctx, env, args, fsys, stdout, stderr)
	if err != nil && !errors.Is(err, flag.ErrHelp) {
		return 1
	}
	return 0
}

func printKnownSubcommands(out io.Writer, prog string, cmds map[string]Runner) {
	name := filepath.Base(prog)
	keys := make([]string, 0, len(cmds))
	for k := range cmds {
		keys = append(keys, k)
	}
	slices.Sort(keys)
	fmt.Fprint(out, "Usage of ", name, ":\n")
	fmt.Fprint(out, "\t", name, " subcmd ", "[flags...]\n")
	fmt.Fprint(out, "\nKnown subcmds:\n")
	for _, k := range keys {
		fmt.Fprintln(out, "\t", k)
	}
	fmt.Fprintln(out)
}
