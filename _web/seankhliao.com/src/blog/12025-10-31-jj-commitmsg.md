# jj-commitmsg

# generating the right prefix

### jj-commitmsg

I quite like the [Go project commit message](https://go.dev/doc/contribute#first_line)
style of "package/scope: some message" for the first line.

Using plain git,
the [`commit.verbose = true`](https://git-scm.com/docs/git-commit#Documentation/git-commit.txt---verbose)
setting can help by showing the diff in the commit message editor helping you remember the paths you changed.
But it's still manual.

I never got around to automating this with `git`,
though I did with [`jj`](https://jj-vcs.github.io/jj/latest/).

The following is a simple program I invoke with `jj commit -m "$(jj-commitmsg): some message"`.
It finds the common prefix between all modified files,
or otherwise `all`.
I call `jj describe -r @-` if I need to expand on it.
jj does have a [templating language](https://jj-vcs.github.io/jj/latest/templates/)
but I don't think it's flexible enough to do this.

```go
package main

import (
        "context"
        "fmt"
        "os"
        "os/exec"
        "path"
        "strings"
)

func main() {
        ctx := context.Background()
        rootDirs, err := run(ctx, "jj", "workspace", "root")
        if err != nil || len(rootDirs) != 1 {
                fmt.Fprintln(os.Stderr, "find workspace root", rootDirs, err)
                os.Exit(1)
        }
        os.Chdir(rootDirs[0])
        diffFiles, err := run(ctx, "jj", "diff", "--name-only")
        if err != nil {
                fmt.Fprintln(os.Stderr, "find changed files", err)
                os.Exit(1)
        } else if len(diffFiles) == 0 {
                fmt.Fprintln(os.Stderr, "no changed files")
                os.Exit(1)
        }

        common := diffFiles[0]
findCommon:
        for {
                common = path.Dir(common)
                if common == "." {
                        common = "all"
                        break findCommon
                }
                allMatch := true
                for _, file := range diffFiles {
                        if !strings.HasPrefix(file, common) {
                                allMatch = false
                        }
                }
                if allMatch {
                        break findCommon
                }
        }
        fmt.Print(common)
}

func run(ctx context.Context, cmd string, args ...string) ([]string, error) {
        b, err := exec.CommandContext(ctx, cmd, args...).Output()
        if err != nil {
                return nil, fmt.Errorf("exec %v %v: %w", cmd, args, err)
        }
        lines := strings.FieldsFunc(string(b), func(r rune) bool {
                return r == '\n'
        })
        return lines, nil
}
```
