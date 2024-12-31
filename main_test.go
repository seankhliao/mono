package main

import (
	"os/exec"
	"testing"
)

// go vet ./...
// go tool staticcheck ./...
// go tool buf lint .
// go tool cue vet -c=false ./...
// go tool govulncheck ./...

func TestLint(t *testing.T) {
	t.Parallel()

	linters := []struct {
		name string
		args []string
	}{
		{
			"vet",
			[]string{"go", "vet", "./..."},
		}, {
			"staticcheck",
			[]string{"go", "tool", "staticcheck", "./..."},
		}, {
			"govulncheck",
			[]string{"go", "tool", "govulncheck", "./..."},
		}, {
			"buf lint",
			[]string{"go", "tool", "buf", "lint", "."},
		}, {
			"cue vet",
			[]string{"go", "tool", "cue", "vet", "-c=false", "./..."},
		},
	}

	for _, tc := range linters {
		t.Run(tc.name, func(t *testing.T) {
			b, err := exec.CommandContext(t.Context(), tc.args[0], tc.args[1:]...).CombinedOutput()
			if err != nil {
				t.Errorf("%s: %v\n%s", tc.name, err, string(b))
			}
		})
	}
}
