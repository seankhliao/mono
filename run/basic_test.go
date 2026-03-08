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

func TestCommandBasic(t *testing.T) {
	tcs := []testCommandCase{
		{
			&CommandBasic[struct{}]{
				Name: "basic",
				Desc: "a description",
				Do: func(c *struct{}) Runner {
					return func(ctx context.Context, in io.Reader, out, err io.Writer, fsys fs.FS) int {
						fmt.Fprintln(out, "hello world")
						return 0
					}
				},
			},
			[]string{"basic"},
			[]string{
				"hello world",
			},
			nil,
			0,
		}, {
			&CommandBasic[struct{}]{
				Name: "help-text",
				Desc: "a description",
				Do: func(c *struct{}) Runner {
					return func(ctx context.Context, in io.Reader, out, err io.Writer, fsys fs.FS) int {
						fmt.Fprintln(out, "hello world")
						return 0
					}
				},
			},
			[]string{"basic", "-help"},
			[]string{
				"Usage: help-text",
			},
			nil,
			0,
		}, {
			&CommandBasic[struct{}]{
				Name: "unknown-flag",
				Desc: "a description",
				Do: func(c *struct{}) Runner {
					return func(ctx context.Context, in io.Reader, out, err io.Writer, fsys fs.FS) int {
						fmt.Fprintln(out, "hello world")
						return 0
					}
				},
			},
			[]string{"basic", "-x"},
			nil,
			[]string{
				"x",
			},
			1,
		}, {
			&CommandBasic[struct{}]{
				Name: "unknown-arg",
				Desc: "a description",
				Do: func(c *struct{}) Runner {
					return func(ctx context.Context, in io.Reader, out, err io.Writer, fsys fs.FS) int {
						fmt.Fprintln(out, "hello world")
						return 0
					}
				},
			},
			[]string{"basic", "x"},
			nil,
			[]string{
				"x",
			},
			1,
		}, {
			&CommandBasic[struct {
				F string
			}]{
				Name: "set-flag",
				Desc: "a description",
				Flags: func(c *struct{ F string }, fset *flag.FlagSet) error {
					fset.StringVar(&c.F, "a-flag", "default-value", "a boolean flag")
					return nil
				},
				Do: func(c *struct{ F string }) Runner {
					return func(ctx context.Context, in io.Reader, out, err io.Writer, fsys fs.FS) int {
						fmt.Fprintln(out, c.F)
						return 0
					}
				},
			},
			[]string{"basic", "-a-flag=some-value"},
			[]string{
				"some-value",
			},
			nil,
			0,
		}, {
			&CommandBasic[struct {
				F string
			}]{
				Name: "debug-flag",
				Desc: "a description",
				Flags: func(c *struct{ F string }, fset *flag.FlagSet) error {
					fset.StringVar(&c.F, "a-flag", "default-value", "a boolean flag")
					return nil
				},
				Do: func(c *struct{ F string }) Runner {
					return func(ctx context.Context, in io.Reader, out, err io.Writer, fsys fs.FS) int {
						fmt.Fprintln(out, c.F)
						return 0
					}
				},
			},
			[]string{"basic", "-flag-debug"},
			[]string{
				"-a-flag=default-value",
			},
			nil,
			0,
		}, {
			&CommandBasic[struct {
				V [5]string
			}]{
				Name: "flag-file-1",
				Desc: "read flags from files",
				Flags: func(c *struct{ V [5]string }, fset *flag.FlagSet) error {
					fset.StringVar(&c.V[0], "foo", "default", "help")
					fset.StringVar(&c.V[1], "bar", "default", "help")
					fset.StringVar(&c.V[2], "qux", "default", "help")
					fset.StringVar(&c.V[3], "fizz", "default", "help")
					fset.StringVar(&c.V[4], "buzz", "default", "help")
					return nil
				},
				Do: func(c *struct{ V [5]string }) Runner {
					return func(ctx context.Context, in io.Reader, out, err io.Writer, fsys fs.FS) int {
						fmt.Fprintln(out, c.V)
						if !slices.Equal(c.V[:], []string{"lorem", "ipsum", "dolor", "sit amet", "consectetur adipiscing"}) {
							return 1
						}
						return 0
					}
				},
			},
			[]string{"x", "-flag-file", "testdata/basic/flag-file-1/flags.txt"},
			[]string{
				"lorem ipsum dolor sit amet consectetur adipiscing",
			},
			nil,
			0,
		}, {
			CommandRun("run", "some dec", func(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) int {
				fmt.Fprintln(stdout, "hello world")
				return 0
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
