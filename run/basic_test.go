package run

import (
	"bytes"
	"context"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"os"
	"path/filepath"
	"regexp"
	"slices"
	"testing"
)

type testSimpler struct {
	flags func(*flag.FlagSet) error
	run   Runner
}

func (s *testSimpler) Flags(fset *flag.FlagSet) error {
	if s.flags != nil {
		return s.flags(fset)
	}
	return nil
}

func (s *testSimpler) Run(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	return s.run(ctx, stdin, stdout, stderr, fsys)
}

func TestSimpleFunc(t *testing.T) {
	tcs := []testCommandCase{
		{
			Func("basic", "a description", func(ctx context.Context, in io.Reader, out, err io.Writer, fsys fs.FS) error {
				fmt.Fprintln(out, "hello world")
				return nil
			}),
			[]string{"basic"},
			[]string{
				"hello world",
			},
			nil,
			0,
		}, {
			Func("help-text", "a description", func(ctx context.Context, in io.Reader, out, err io.Writer, fsys fs.FS) error {
				fmt.Fprintln(out, "hello world")
				return nil
			}),
			[]string{"basic", "-help"},
			[]string{
				"Usage: help-text",
			},
			nil,
			0,
		}, {
			Func("unknown-flag", "a description", func(ctx context.Context, in io.Reader, out, err io.Writer, fsys fs.FS) error {
				fmt.Fprintln(out, "hello world")
				return nil
			}),
			[]string{"basic", "-x"},
			nil,
			[]string{
				"x",
			},
			1,
		}, {
			Func("unknown-arg", "a description", func(ctx context.Context, in io.Reader, out, err io.Writer, fsys fs.FS) error {
				fmt.Fprintln(out, "hello world")
				return nil
			}),
			[]string{"basic", "x"},
			nil,
			[]string{
				"x",
			},
			1,
		}, {
			func() Commander {
				type conf struct{ F string }
				c := &conf{}
				return Simple("set-flag", "a description", &testSimpler{
					flags: func(fset *flag.FlagSet) error {
						fset.StringVar(&c.F, "a-flag", "default-value", "a boolean flag")
						return nil
					},
					run: func(ctx context.Context, in io.Reader, out, err io.Writer, fsys fs.FS) error {
						fmt.Fprintln(out, c.F)
						return nil
					},
				})
			}(),
			[]string{"basic", "-a-flag=some-value"},
			[]string{
				"some-value",
			},
			nil,
			0,
		}, {
			func() Commander {
				type conf struct{ F string }
				c := &conf{}
				return Simple("debug-flag", "a description", &testSimpler{
					flags: func(fset *flag.FlagSet) error {
						fset.StringVar(&c.F, "a-flag", "default-value", "a boolean flag")
						return nil
					},
					run: func(ctx context.Context, in io.Reader, out, err io.Writer, fsys fs.FS) error {
						fmt.Fprintln(out, c.F)
						return nil
					},
				})
			}(),
			[]string{"basic", "-flag-debug"},
			[]string{
				"-a-flag=default-value",
			},
			nil,
			0,
		}, {
			func() Commander {
				type conf struct{ V [5]string }
				c := &conf{}
				return Simple("flag-file-1", "read flags from files", &testSimpler{
					flags: func(fset *flag.FlagSet) error {
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
		}, {
			Func("run", "some dec", func(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
				fmt.Fprintln(stdout, "hello world")
				return nil
			}),
			[]string{"run"},
			[]string{
				"hello world",
			},
			nil,
			0,
		},
	}

	for _, tc := range tcs {
		testCommand(t, "basic", tc)
	}
}

type testCommandCase struct {
	c Commander

	args   []string
	stdout []string
	stderr []string
	exit   int
}

func testCommand(t *testing.T, cmdType string, tc testCommandCase) {
	t.Helper()
	t.Run(tc.c.CmdName(), func(t *testing.T) {
		stdin := bytes.NewReader([]byte(nil))
		var stdout, stderr bytes.Buffer
		fsys := os.DirFS(filepath.Join("testdata", cmdType, tc.c.CmdName()))

		t.Logf("args: %v", tc.args)
		gotExit := Exec(tc.c, tc.args, stdin, &stdout, &stderr, fsys)
		if gotExit != tc.exit {
			t.Errorf("exit code = %d, want = %d", gotExit, tc.exit)
		}

		gotStdout := stdout.Bytes()
		t.Log("stdout:", string(gotStdout))
		for _, reg := range tc.stdout {
			r := regexp.MustCompile(reg)
			t.Logf("stdout regexp: %v", r)
			if !r.Match(gotStdout) {
				t.Errorf("didn't match stdout: %v", r)
			}

		}

		gotStderr := stderr.Bytes()
		t.Log("stderr:", string(gotStderr))
		for _, reg := range tc.stderr {
			r := regexp.MustCompile(reg)
			t.Logf("stderr regexp: %v", r)
			if !r.Match(gotStderr) {
				t.Errorf("didn't match stderr: %v", r)
			}

		}
	})
}
