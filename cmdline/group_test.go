package cmdline

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
			&CommandGroup{
				"no-subs",
				"a description",
				nil,
			},
			[]string{"group"},
			nil,
			[]string{
				"Usage: no-subs",
			},
			1,
		}, {
			&CommandGroup{
				"match-subs",
				"a description",
				[]Commander{
					&CommandBasic[struct{}]{
						Name: "sub1",
						Desc: "sub description",
						Do: func(c *struct{}) Runner {
							return func(ctx context.Context, in io.Reader, out, err io.Writer, fsys fs.FS) int {
								fmt.Fprintln(out, "hello world")
								return 0
							}
						},
					},
				},
			},
			[]string{"group", "sub1"},
			[]string{
				"hello world",
			},
			nil,
			0,
		}, {
			&CommandGroup{
				"no-match-subs",
				"a description",
				[]Commander{
					&CommandBasic[struct{}]{
						Name: "sub1",
						Desc: "sub description",
						Do: func(c *struct{}) Runner {
							return func(ctx context.Context, in io.Reader, out, err io.Writer, fsys fs.FS) int {
								fmt.Fprintln(out, "hello world")
								return 0
							}
						},
					},
				},
			},
			[]string{"group", "sub2"},
			nil,
			[]string{
				"Usage: no-match-subs",
			},
			1,
		}, {
			&CommandGroup{
				"nested-match-subs",
				"a description",
				[]Commander{
					&CommandGroup{
						"level1",
						"sub level 1",
						[]Commander{
							&CommandBasic[struct{}]{
								Name: "level2",
								Desc: "sub level 2",
								Do: func(c *struct{}) Runner {
									return func(ctx context.Context, in io.Reader, out, err io.Writer, fsys fs.FS) int {
										fmt.Fprintln(out, "hello world")
										return 0
									}
								},
							},
						},
					},
				},
			},
			[]string{"group", "level1", "level2"},
			[]string{
				"hello world",
			},
			nil,
			0,
		}, {
			&CommandGroup{
				"nested-match-subs",
				"a description",
				[]Commander{
					&CommandGroup{
						"level1",
						"sub level 1",
						[]Commander{
							&CommandBasic[struct{}]{
								Name: "level2",
								Desc: "sub level 2",
								Do: func(c *struct{}) Runner {
									return func(ctx context.Context, in io.Reader, out, err io.Writer, fsys fs.FS) int {
										fmt.Fprintln(out, "hello world")
										return 0
									}
								},
							},
							&CommandGroup{
								"no-subs",
								"a description",
								nil,
							},
						},
					},
				},
			},
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
