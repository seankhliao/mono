package run

import (
	"context"
	"fmt"
	"io"
	"io/fs"
	"testing"
)

func TestCommandGroup(t *testing.T) {
	tcs := []testCommandCase{
		{
			Group("no-subs", "a description"),
			[]string{"group"},
			nil,
			[]string{
				"Usage: no-subs",
			},
			1,
		}, {
			Group("match-subs", "a description",
				Func("sub1", "sub description", func(ctx context.Context, in io.Reader, out, err io.Writer, fsys fs.FS) error {
					fmt.Fprintln(out, "hello world")
					return nil
				}),
			),
			[]string{"group", "sub1"},
			[]string{
				"hello world",
			},
			nil,
			0,
		}, {
			Group("no-match-subs", "a description",
				Func("sub1", "sub description", func(ctx context.Context, in io.Reader, out, err io.Writer, fsys fs.FS) error {
					fmt.Fprintln(out, "hello world")
					return nil
				}),
			),
			[]string{"group", "sub2"},
			nil,
			[]string{
				"Usage: no-match-subs",
			},
			1,
		}, {
			Group("nested-match-subs", "a description",
				Group("level1", "sub level 1",
					Func("level2", "sub level 2", func(ctx context.Context, in io.Reader, out, err io.Writer, fsys fs.FS) error {
						fmt.Fprintln(out, "hello world")
						return nil
					}),
				),
			),
			[]string{"group", "level1", "level2"},
			[]string{
				"hello world",
			},
			nil,
			0,
		}, {
			Group("nested-match-subs", "a description",
				Group("level1", "sub level 1",
					Func("level2", "sub level 2", func(ctx context.Context, in io.Reader, out, err io.Writer, fsys fs.FS) error {
						fmt.Fprintln(out, "hello world")
						return nil
					}),
					Group("no-subs", "a description"),
				),
			),
			[]string{"group", "level1", "no-match"},
			nil,
			[]string{
				"Usage: nested-match-subs level1",
			},
			1,
		},
	}

	for _, tc := range tcs {
		testCommand(t, "group", tc)
	}
}
