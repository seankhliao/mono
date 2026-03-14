package run

import (
	"context"
	"fmt"
	"io"
	"io/fs"
	"testing"
)

func TestFunc(t *testing.T) {
	tcs := []testCommandCase{{
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
		[]string{"help-text", "-help"},
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
		[]string{"unknown-flag", "-x"},
		nil,
		[]string{
			"Usage: unknown-flag",
			"-x",
		},
		1,
	}, {
		Func("unknown-arg", "a description", func(ctx context.Context, in io.Reader, out, err io.Writer, fsys fs.FS) error {
			fmt.Fprintln(out, "hello world")
			return nil
		}),
		[]string{"unknown-arg", "x"},
		nil,
		[]string{
			"Usage: unknown-arg",
			"x",
		},
		1,
	}}

	for _, tc := range tcs {
		testCommand(t, "basic", tc)
	}
}
