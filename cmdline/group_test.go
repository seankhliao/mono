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
				Name: "no-subs",
				Desc: "a description",
				Subs: nil,
			},
			[]string{"group"},
			nil,
			[]string{
				"Usage: no-subs",
			},
			1,
		}, {
			&CommandGroup{
				Name: "match-subs",
				Desc: "a description",
				Subs: []Commander{
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
				Name: "no-match-subs",
				Desc: "a description",
				Subs: []Commander{
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
				Name: "nested-match-subs",
				Desc: "a description",
				Subs: []Commander{
					&CommandGroup{
						Name: "level1",
						Desc: "sub level 1",
						Subs: []Commander{
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
				Name: "nested-match-subs",
				Desc: "a description",
				Subs: []Commander{
					&CommandGroup{
						Name: "level1",
						Desc: "sub level 1",
						Subs: []Commander{
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
								Name: "no-subs",
								Desc: "a description",
								Subs: nil,
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
