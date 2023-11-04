package main

import (
	"bufio"
	"bytes"
	"os"
	"testing"
)

func readFile(t *testing.T, name string) []byte {
	t.Helper()

	b, err := os.ReadFile("testdata/" + name)
	if err != nil {
		t.Fatalf("read %s: %v", name, err)
	}
	return b
}

func lineCmp(t *testing.T, got, want []byte) {
	t.Helper()

	gotSc := bufio.NewScanner(bytes.NewReader(got))
	wantSc := bufio.NewScanner(bytes.NewReader(want))
	for idx := 1; gotSc.Scan(); idx++ {
		if !wantSc.Scan() {
			t.Fatal("more output than expected")
		}

		if gotSc.Text() != wantSc.Text() {
			t.Errorf("L%d: %q != %q", idx, gotSc.Text(), wantSc.Text())
		}
	}
	if wantSc.Scan() {
		t.Fatal("less output than expected")
	}
}

func TestStripAnsi(t *testing.T) {
	input := readFile(t, "color.txt")
	golden := readFile(t, "nocolor.txt")

	output := ansi.ReplaceAll(input, nil)
	lineCmp(t, output, golden)
}

func TestOutputToAliases(t *testing.T) {
	input := readFile(t, "color.txt")
	goldenAlias := readFile(t, "alias.txt")
	goldenConsole := readFile(t, "console.txt")

	var alias, console bytes.Buffer
	outputToAliases(&alias, &console, bytes.NewReader(input), "/abs", false)
	t.Run("alias", func(t *testing.T) {
		lineCmp(t, alias.Bytes(), goldenAlias)
	})
	t.Run("console", func(t *testing.T) {
		lineCmp(t, console.Bytes(), goldenConsole)
	})
}
