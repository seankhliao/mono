//go:build deps

package main

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
)

//go:generate go run deps.go
//go:generate go get honnef.co/go/tools/cmd/staticcheck@master
//go:generate go get -u=patch all
//go:generate go run github.com/bufbuild/buf/cmd/buf dep update

func main() {
	b, err := exec.Command(`go`, `list`, `-m`, `-f`, `{{ if not (or .Main .Indirect) }}{{ printf "%s\n" .Path }}{{ end }}`, `all`).Output()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	directDeps := strings.Fields(string(b))
	cmd := exec.Command("go", append([]string{"get", "-u"}, directDeps...)...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err = cmd.Run()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
