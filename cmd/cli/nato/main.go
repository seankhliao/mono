package main

import (
	"fmt"
	"log/slog"
	"os"
)

func main() {
	err := run()
	if err != nil {
		slog.Error("run", "err", err)
		os.Exit(1)
	}
}

func run() error {
	args := os.Args[1:]
	if len(args) == 0 {
		for i := range 'Z' - 'A' {
			r := 'A' + i
			fmt.Printf("%c\t%v\n", r, nato[r])
		}
		return nil
	}

	for _, arg := range args {
		for _, r := range arg {
			switch {
			case r == ' ':
				fmt.Println()
			case 'a' <= r && r <= 'z':
				r += 'A' - 'a'
				fallthrough
			case 'A' <= r && r <= 'Z':
				fmt.Printf("%c\t%v\n", r, nato[r])
			default:
				fmt.Println(r)
			}
		}
		fmt.Println()
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
