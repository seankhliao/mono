package main

import (
	"context"
	"fmt"
	"io"
	"io/fs"
	"os"

	"go.seankhliao.com/mono/run"
)

func main() {
	run.OSExec(run.Func("nato", "print nato phonetic alphabet", f))
}

func f(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	args := os.Args[1:]
	if len(args) == 0 {
		for i := range 'Z' - 'A' {
			r := 'A' + i
			fmt.Fprintf(stdout, "%c\t%v\n", r, nato[r])
		}
		return nil
	}

	for _, arg := range args {
		for _, r := range arg {
			switch {
			case r == ' ':
				fmt.Fprintln(stdout)
			case 'a' <= r && r <= 'z':
				r += 'A' - 'a'
				fallthrough
			case 'A' <= r && r <= 'Z':
				fmt.Fprintf(stdout, "%c\t%v\n", r, nato[r])
			default:
				fmt.Fprintln(stdout, r)
			}
		}
		fmt.Fprintln(stdout)
	}

	return nil
}

var nato = map[rune]string{
	'A': "Alfa",
	'B': "Bravo",
	'C': "Charlie",
	'D': "Delta",
	'E': "Echo",
	'F': "Foxtrot",
	'G': "Golf",
	'H': "Hotel",
	'I': "India",
	'J': "Juliett",
	'K': "Kilo",
	'L': "Lima",
	'M': "Mike",
	'N': "November",
	'O': "Oscar",
	'P': "Papa",
	'Q': "Quebec",
	'R': "Romeo",
	'S': "Sierra",
	'T': "Tango",
	'U': "Uniform",
	'V': "Victor",
	'W': "Whiskey",
	'X': "Xray",
	'Y': "Yankee",
	'Z': "Zulu",
}
