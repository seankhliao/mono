package main

import (
	"context"
	"errors"
	"fmt"
	"io/fs"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"syscall"
)

var debug = os.Getenv("DEBUG") == "1"

func main() {
	ctx := context.Background()
	ctx, done := signal.NotifyContext(ctx, syscall.SIGINT, syscall.SIGTERM)
	defer done()

	err := run(ctx)
	if err != nil {
		fmt.Fprintln(os.Stderr, "pre-commit", err)
		os.Exit(1)
	}
}

func run(ctx context.Context) error {
	tools, err := selectTools()
	if err != nil {
		return err
	}

	for i, tool := range tools {
		if debug {
			fmt.Fprintln(os.Stderr, "running tool", i, tool.name)
		}
		out, err := tool.run(ctx)
		var exit *exec.ExitError
		if errors.As(err, &exit) {
			if tool.allowfail {
				continue
			}
			return fmt.Errorf("tool %d %q exited with nonzero status %d, out:\n%s", i, tool.name, exit.ExitCode(), out)
		} else if err != nil {
			return fmt.Errorf("tool %d %q unexpected error: %w", i, tool.name, err)
		}
	}
	return nil
}

type tool struct {
	name      string
	run       func(ctx context.Context) ([]byte, error)
	allowfail bool
}

func selectTools() ([]tool, error) {
	var cuefiles, gofiles []string
	var prettier, terraform, misspell bool
	err := filepath.WalkDir(".", func(p string, d fs.DirEntry, err error) error {
		if err != nil || d.IsDir() {
			if d.Name() == ".git" {
				return fs.SkipDir
			}
			return err
		}
		switch filepath.Ext(d.Name()) {
		case ".css", ".html", ".json", ".md", ".yaml":
			prettier = true
			misspell = true
		case ".go":
			gofiles = append(gofiles, p)
			misspell = true
		case ".cue":
			fmt.Println(p, d.Name())
			cuefiles = append(cuefiles, p)
		case ".tf":
			terraform = true
		}
		return nil
	})
	if err != nil {
		return nil, fmt.Errorf("select tools: walk over '.': %w", err)
	}

	var tools []tool
	if misspell {
		tools = append(tools, tool{
			name: "misspell",
			run: func(ctx context.Context) ([]byte, error) {
				return exec.CommandContext(ctx,
					"misspell", "-w", "-q", ".",
				).CombinedOutput()
			},
		})
	}
	if prettier {
		tools = append(tools, tool{
			name: "prettier",
			run: func(ctx context.Context) ([]byte, error) {
				return exec.CommandContext(ctx,
					"prettier", "-w", ".",
				).CombinedOutput()
			},
		})
	}
	if len(cuefiles) > 0 {
		tools = append(tools, tool{
			name: "cue fmt",
			run: func(ctx context.Context) ([]byte, error) {
				return exec.CommandContext(ctx,
					"cue", append([]string{"fmt"}, cuefiles...)...,
				).CombinedOutput()
			},
		})
	}
	if terraform {
		tools = append(tools, tool{
			name: "terraform fmt",
			run: func(ctx context.Context) ([]byte, error) {
				return exec.CommandContext(ctx,
					"terraform", "fmt", "-write", "-recursive", ".",
				).CombinedOutput()
			},
		})
	}
	if len(gofiles) > 0 {
		godirsm := make(map[string]struct{})
		for _, dir := range gofiles {
			godirsm[filepath.Dir(dir)] = struct{}{}
		}
		godirs := make([]string, 0, len(godirsm))
		for dir := range godirsm {
			godirs = append(godirs, dir)
		}
		tools = append(tools, tool{
			name: "go mod tidy",
			run: func(ctx context.Context) ([]byte, error) {
				return exec.CommandContext(ctx,
					"go", "mod", "tidy",
				).CombinedOutput()
			},
		}, tool{
			name: "gofumpt",
			run: func(ctx context.Context) ([]byte, error) {
				return exec.CommandContext(ctx,
					"gofumpt", append([]string{"-w"}, godirs...)...,
				).CombinedOutput()
			},
		}, tool{
			name: "go vet",
			run: func(ctx context.Context) ([]byte, error) {
				return exec.CommandContext(ctx,
					"go", "vet", "./...",
				).CombinedOutput()
			},
		}, tool{
			name: "staticcheck",
			run: func(ctx context.Context) ([]byte, error) {
				return exec.CommandContext(ctx,
					"staticcheck", "./...",
				).CombinedOutput()
			},
		}, tool{
			name: "go build",
			run: func(ctx context.Context) ([]byte, error) {
				return exec.CommandContext(ctx,
					"go", "build", "-o", "/dev/null", "./...",
				).CombinedOutput()
			},
		})
	}
	if len(tools) > 0 {
		tools = append(tools, tool{
			name: "git commit",
			run: func(ctx context.Context) ([]byte, error) {
				return exec.CommandContext(ctx,
					"git", "add", ".",
				).CombinedOutput()
			},
		})
	}
	return tools, nil
}
