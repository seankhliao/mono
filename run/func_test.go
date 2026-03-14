package run

import (
	"context"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"slices"
	"testing"
)

var _ Simpler = &testSimpler{}

type testSimpler struct {
	flags func(*flag.FlagSet, **[]string) error
	run   Runner
}

func (s *testSimpler) Flags(fset *flag.FlagSet, args **[]string) error {
	if s.flags != nil {
		return s.flags(fset, args)
	}
	return nil
}

func (s *testSimpler) Run(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	return s.run(ctx, stdin, stdout, stderr, fsys)
}

func TestSimple(t *testing.T) {
	tcs := []testCommandCase{{
		func() Commander {
			type conf struct{ F string }
			return Simple("simple", "a description", &testSimpler{
				run: func(ctx context.Context, in io.Reader, out, err io.Writer, fsys fs.FS) error {
					fmt.Fprintln(out, "hello world")
					return nil
				},
			})
		}(),
		[]string{"simple"},
		[]string{
			"hello world",
		},
		nil,
		0,
	}, {
		func() Commander {
			type conf struct{ F string }
			return Simple("help-text", "a description", &testSimpler{
				run: func(ctx context.Context, in io.Reader, out, err io.Writer, fsys fs.FS) error {
					fmt.Fprintln(out, "hello world")
					return nil
				},
			})
		}(),
		[]string{"help-text", "-help"},
		[]string{
			"Usage: help-text",
		},
		nil,
		0,
	}, {
		func() Commander {
			type conf struct{ F string }
			return Simple("unknown-flag", "a description", &testSimpler{
				run: func(ctx context.Context, in io.Reader, out, err io.Writer, fsys fs.FS) error {
					fmt.Fprintln(out, "hello world")
					return nil
				},
			})
		}(),
		[]string{"unknown-flag", "-x"},
		nil,
		[]string{
			"Usage: unknown-flag",
			"-x",
		},
		1,
	}, {
		func() Commander {
			type conf struct{ F string }
			return Simple("unknown-arg", "a description", &testSimpler{
				run: func(ctx context.Context, in io.Reader, out, err io.Writer, fsys fs.FS) error {
					fmt.Fprintln(out, "hello world")
					return nil
				},
			})
		}(),
		[]string{"unknown-arg", "x"},
		nil,
		[]string{
			"Usage: unknown-arg",
			"x",
		},
		1,
	}, {
		func() Commander {
			type conf struct{ F string }
			c := &conf{}
			return Simple("set-flag", "a description", &testSimpler{
				flags: func(fset *flag.FlagSet, args **[]string) error {
					fset.StringVar(&c.F, "a-flag", "default-value", "a boolean flag")
					return nil
				},
				run: func(ctx context.Context, in io.Reader, out, err io.Writer, fsys fs.FS) error {
					fmt.Fprintln(out, c.F)
					return nil
				},
			})
		}(),
		[]string{"set-flag", "-a-flag=some-value"},
		[]string{
			"some-value",
		},
		nil,
		0,
	}, {
		func() Commander {
			type conf struct{ A []string }
			c := &conf{}
			return Simple("set-args", "a description", &testSimpler{
				flags: func(fset *flag.FlagSet, args **[]string) error {
					*args = &c.A
					return nil
				},
				run: func(ctx context.Context, in io.Reader, out, err io.Writer, fsys fs.FS) error {
					fmt.Fprintln(out, c.A)
					return nil
				},
			})
		}(),
		[]string{"set-args", "hello", "world"},
		[]string{
			"hello world",
		},
		nil,
		0,
	}, {
		func() Commander {
			type conf struct{ F, G string }
			c := &conf{}
			return Simple("debug-flag", "a description", &testSimpler{
				flags: func(fset *flag.FlagSet, args **[]string) error {
					fset.StringVar(&c.F, "f-flag", "aaa", "a boolean flag")
					fset.StringVar(&c.G, "g-flag", "bbb", "a boolean flag")
					return nil
				},
				run: func(ctx context.Context, in io.Reader, out, err io.Writer, fsys fs.FS) error {
					fmt.Fprintln(out, c.F)
					return nil
				},
			})
		}(),
		[]string{"debug-flag", "-flag-debug", "-g-flag", "ccc"},
		[]string{
			"-f-flag=aaa",
			"-g-flag=ccc",
		},
		nil,
		0,
	}, {
		func() Commander {
			type conf struct{ V [5]string }
			c := &conf{}
			return Simple("flag-file-1", "read flags from files", &testSimpler{
				flags: func(fset *flag.FlagSet, args **[]string) error {
					fset.StringVar(&c.V[0], "foo", "default", "help")
					fset.StringVar(&c.V[1], "bar", "default", "help")
					fset.StringVar(&c.V[2], "qux", "default", "help")
					fset.StringVar(&c.V[3], "fizz", "default", "help")
					fset.StringVar(&c.V[4], "buzz", "default", "help")
					return nil
				},
				run: func(ctx context.Context, in io.Reader, out, err io.Writer, fsys fs.FS) error {
					fmt.Fprintln(out, c.V)
					if !slices.Equal(c.V[:], []string{"lorem", "ipsum", "dolor", "sit amet", "consectetur adipiscing"}) {
						return fmt.Errorf("wrong output")
					}
					return nil
				},
			})
		}(),
		[]string{"x", "-flag-file", "testdata/basic/flag-file-1/flags.txt"},
		[]string{
			"lorem ipsum dolor sit amet consectetur adipiscing",
		},
		nil,
		0,
	}}

	for _, tc := range tcs {
		testCommand(t, "basic", tc)
	}
}
