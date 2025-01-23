package main

import (
	"bufio"
	"bytes"
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
)

const (
	envLong  = "T_LONG"
	helpText = `t [rg flags] search-term

t wraps rg, generating shell aliases to open the nvim at the given file:line.
t should be shadowed by the following shell function to work correctly:

function t() {
    command t -i "$@"
    source /tmp/t_aliases 2>/dev/null
}
`
)

var ansi = regexp.MustCompile(`\x1b\[[0-9;]*[a-zA-Z]`)

func main() {
	if len(os.Args) > 1 && os.Args[1] == "--help" {
		fmt.Fprint(os.Stderr, helpText)
		os.Exit(1)
	}

	cmd := exec.Command("rg", append([]string{"--heading", "--column", "--color=always"}, os.Args[1:]...)...)
	cmd.Stderr = os.Stderr
	rc, err := cmd.StdoutPipe()
	if err != nil {
		log.Fatal(err)
	}
	defer rc.Close()

	f, err := os.Create("/tmp/t_aliases")
	if err != nil {
		log.Fatal(err)
	}
	defer f.Close()

	cmd.Start()
	defer cmd.Wait()

	wd, err := os.Getwd()
	if err != nil {
		log.Fatalln(err)
	}

	outputToAliases(f, os.Stdout, rc, wd, os.Getenv(envLong) == "1")
}

func outputToAliases(alias, console io.Writer, r io.Reader, wdPath string, includeLong bool) {
	var excluded int
	var curPath string

	sc := bufio.NewScanner(r)
	sc.Buffer(make([]byte, 64*1024*1024), 64*1024*1024)
	for idx := 0; sc.Scan(); {
		// blank line between file groups, reset curPath
		if len(sc.Bytes()) == 0 {
			curPath = ""
			fmt.Fprintln(console)
			continue
		}

		plainLine := ansi.ReplaceAll(sc.Bytes(), nil)

		// don't spam the terminal with giant lines like minimized content
		if !includeLong && len(plainLine) > 4096 {
			excluded++
			continue
		}

		// read the file header
		if curPath == "" {
			curPath = filepath.Join(wdPath, string(plainLine))
			fmt.Fprintln(console, sc.Text())
			continue
		}

		idx++
		lineN, rest, _ := bytes.Cut(plainLine, []byte(":"))
		colN, _, _ := bytes.Cut(rest, []byte(":"))

		fmt.Fprintf(alias, `alias e%d='nvim -c "call cursor(%s, %s)" "%s"'`+"\n", idx, lineN, colN, curPath)
		fmt.Fprintf(console, "\x1b[34m[\x1b[31m%d\x1b[34m]\x1b[0m %s\n", idx, sc.Text())
	}

	if excluded > 0 {
		fmt.Fprintf(console, "%d results on long lines excluded, set %s=1 to include", excluded, envLong)
	}
}
