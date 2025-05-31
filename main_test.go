package main

import (
	"flag"
	"os/exec"
	"strings"
	"testing"
)

var fix = flag.Bool("fix", false, "fix (modify) source code")

func TestLint(t *testing.T) {
	t.Parallel()

	linters := []tool{
		{
			"vet",
			[]string{"go", "vet", "./..."},
			nil,
			nil,
		}, {
			"staticcheck",
			[]string{"go", "tool", "staticcheck", "./..."},
			nil,
			nil,
		}, {
			"govulncheck",
			[]string{"go", "tool", "govulncheck", "./..."},
			nil,
			[]any{"govulncheck doesn't work with GOEXPERIMENT=jsonv2"},
		}, {
			"buf lint",
			[]string{"go", "tool", "buf", "lint", "."},
			nil,
			nil,
		}, {
			"cue vet",
			[]string{"go", "tool", "cue", "vet", "-c=false", "./..."},
			nil,
			nil,
		},
	}

	runAll(t, linters)
}

func TestFormat(t *testing.T) {
	if !*fix {
		t.Parallel()
	}

	formatters := []tool{
		{
			"mod tidy",
			[]string{"go", "mod", "tidy", "-diff"},
			[]string{"go", "mod", "tidy"},
			nil,
		}, {
			"gofumpt",
			[]string{"go", "tool", "gofumpt", "-d", "."},
			[]string{"go", "tool", "gofumpt", "-w", "."},
			nil,
		}, {
			"cue fmt",
			[]string{"go", "tool", "cue", "fmt", "--check", "--diff", "./..."},
			[]string{"go", "tool", "cue", "fmt", "./..."},
			nil,
		}, {
			"buf fmt",
			[]string{"go", "tool", "buf", "format", "--exit-code", "--diff", "."},
			[]string{"go", "tool", "buf", "format", "-w", "."},
			nil,
		},
	}

	runAll(t, formatters)
}

func TestSpell(t *testing.T) {
	ignored := strings.Join([]string{"rebounce"}, ",")
	spells := []tool{{
		"misspell",
		[]string{"go", "tool", "misspell", "-i", ignored, "-error", "."},
		[]string{"go", "tool", "misspell", "-i", ignored, "-w", "."},
		nil,
	}}

	runAll(t, spells)
}

type tool struct {
	name string
	args []string
	fix  []string
	skip []any
}

func runAll(t *testing.T, tos []tool) {
	t.Helper()

	for _, tc := range tos {
		t.Run(tc.name, func(t *testing.T) {
			if len(tc.skip) > 0 {
				t.Skip(tc.skip...)
			}
			cmd, args := tc.args[0], tc.args[1:]
			if !*fix {
				t.Parallel()
			} else {
				if len(tc.fix) == 0 {
					t.Skip("no fixer available")
				}
				cmd, args = tc.fix[0], tc.fix[1:]
			}

			b, err := exec.CommandContext(t.Context(), cmd, args...).CombinedOutput()
			if err != nil {
				t.Errorf("%s: %v\n%s", tc.name, err, string(b))
				if len(tc.fix) > 0 {
					t.Log("fix available, run with: go test -fix")
				}
			}
		})
	}
}
