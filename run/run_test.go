package run

import (
	"bytes"
	"os"
	"path/filepath"
	"regexp"
	"testing"
)

type testCommandCase struct {
	c Commander

	args   []string
	stdout []string
	stderr []string
	exit   int
}

func testCommand(t *testing.T, cmdType string, tc testCommandCase) {
	t.Helper()
	t.Run(tc.c.CmdName(), func(t *testing.T) {
		stdin := bytes.NewReader([]byte(nil))
		var stdout, stderr bytes.Buffer
		fsys := os.DirFS(filepath.Join("testdata", cmdType, tc.c.CmdName()))

		t.Logf("args: %v", tc.args)
		gotExit := Exec(tc.c, tc.args, stdin, &stdout, &stderr, fsys)
		if gotExit != tc.exit {
			t.Errorf("exit code = %d, want = %d", gotExit, tc.exit)
		}

		gotStdout := stdout.Bytes()
		t.Log("stdout:", string(gotStdout))
		for _, reg := range tc.stdout {
			r := regexp.MustCompile(reg)
			t.Logf("stdout regexp: %v", r)
			if !r.Match(gotStdout) {
				t.Errorf("didn't match stdout: %v", r)
			}

		}

		gotStderr := stderr.Bytes()
		t.Log("stderr:", string(gotStderr))
		for _, reg := range tc.stderr {
			r := regexp.MustCompile(reg)
			t.Logf("stderr regexp: %v", r)
			if !r.Match(gotStderr) {
				t.Errorf("didn't match stderr: %v", r)
			}

		}
	})
}
