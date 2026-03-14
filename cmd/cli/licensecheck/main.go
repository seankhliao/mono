package main

import (
	"context"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"log/slog"
	"os"

	"github.com/google/licensecheck"
	"go.seankhliao.com/mono/run"
)

type Config struct {
	File string
}

func main() {
	run.OSExec(run.Simple("licensecheck", "run google/licensecheck on the given file", &Config{}))
}

func (c *Config) Flags(fset *flag.FlagSet, args **[]string) error {
	fset.StringVar(&c.File, "file", "LICENSE", "path to file to check")
	return nil
}

func (c *Config) Run(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	b, err := os.ReadFile(c.File)
	if err != nil {
		return fmt.Errorf("read file %s: %w", c.File, err)
	}

	cov := licensecheck.Scan(b)
	slog.Info("cov", "percent", cov.Percent)
	for _, m := range cov.Match {
		fmt.Fprintf(stdout, "match: %+v\n", m)
	}
	return nil
}
