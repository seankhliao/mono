package main

import (
	"bytes"
	"errors"
	"io"
	"io/fs"
	"log/slog"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

func main() {
	in := os.Args[1]
	out := os.Args[2]

	done := make(map[string]struct{})

	des, err := os.ReadDir(out)
	if err == nil {
		for _, de := range des {
			if de.IsDir() || strings.HasSuffix(de.Name(), ".jpg") {
				continue
			}
			done[de.Name()] = struct{}{}

			if strings.HasPrefix(de.Name(), ".") {
				os.Remove(filepath.Join(out, de.Name()))
			}
		}
	} else if !errors.Is(err, fs.ErrNotExist) {
		slog.Error("list dst", "err", err)
		os.Exit(1)
	}

	des, err = os.ReadDir(in)
	if err != nil {
		slog.Error("list src", "err", err)
		os.Exit(1)
	}

	todo := make(map[string]struct{})

	for _, de := range des {
		if de.IsDir() || strings.HasSuffix(de.Name(), ".jpg") {
			continue
		}
		if _, ok := done[de.Name()]; ok {
			continue
		}
		todo[de.Name()] = struct{}{}
	}

	slog.Info("starting", "total", len(des), "todo", len(todo))

	stdout := &prefixer{w: os.Stdout, p: "\t[out] "}
	stderr := &prefixer{w: os.Stdout, p: "\t[err] "}

	var i int
	for name := range todo {
		i++
		slog.Info("staring", "name", name, "idx", i, "total_todo", len(todo))

		fullname := filepath.Join(in, name)
		tmpout := filepath.Join(out, ".tmp."+name)
		cmd := exec.Command("ffmpeg", "-i", fullname, "-c:v", "libsvtav1", "-cpu-used", "8", "-c:a", "copy", tmpout)
		cmd.Stdout = stdout
		cmd.Stderr = stderr
		err = cmd.Run()
		if err != nil {
			slog.Error("run ffmpeg", "name", name, "err", err)
			continue
		}
		outname := filepath.Join(out, name)
		os.Rename(tmpout, outname)
		slog.Info("done, renamed", "name", name, "idx", i, "total_todo", len(todo))
	}
}

type prefixer struct {
	w io.Writer
	p string
	u bool

	buf bytes.Buffer
}

func (p prefixer) Write(b []byte) (int, error) {
	if !p.u {
		p.u = true
		p.buf.WriteString(p.p)
	}
	bbb := bytes.Split(b, []byte("\n"))
	for i, bb := range bbb {
		p.buf.Write(bb)
		if i != len(bbb)-1 {
			p.buf.WriteRune('\n')
			p.buf.WriteString(p.p)
		}
	}
	p.buf.WriteTo(p.w)
	p.buf.Reset()
	return len(b), nil
}
