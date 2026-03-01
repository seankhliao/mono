package main

import (
	"bytes"
	"flag"
	"fmt"
	"io"
	"log/slog"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

func main() {
	var indir, donedir, outdir, faileddir string
	flag.StringVar(&indir, "in", "todo", "input directory")
	flag.StringVar(&donedir, "done", "done", "done directory")
	flag.StringVar(&outdir, "out", "out", "output directory")
	flag.StringVar(&faileddir, "failed", "failed", "failed directory")
	flag.Parse()

	err := run(indir, donedir, outdir, faileddir)
	if err != nil {
		os.Exit(1)
		fmt.Fprintln(os.Stderr, err)
	}
}

func run(indir, donedir, outdir, faileddir string) error {
	outprefixes, doneprefixes := make(map[string]struct{}), make(map[string]struct{})
	des, err := os.ReadDir(outdir)
	if err != nil {
		return fmt.Errorf("read out dir %s: %w", outdir, err)
	}
	for _, de := range des {
		outprefixes[de.Name()] = struct{}{}
	}
	des, err = os.ReadDir(donedir)
	if err != nil {
		return fmt.Errorf("read done dir %s: %w", outdir, err)
	}
	for _, de := range des {
		doneprefixes[de.Name()] = struct{}{}
	}

	todo := make(map[string]struct{})
	des, err = os.ReadDir(indir)
	if err != nil {
		return fmt.Errorf("read indir %s: %w", indir, err)
	}
	for _, de := range des {
		if de.IsDir() || strings.HasSuffix(de.Name(), ".jpg") {
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

		inname := filepath.Join(indir, name)

		var outprefix, doneprefix string
		for p := range outprefixes {
			if strings.HasPrefix(name, p) {
				outprefix = p
				break
			}
		}
		if outprefix == "" && len(name) > 10 && name[1] == '_' {
			outprefix = name[:4]
			outprefixes[outprefix] = struct{}{}
			os.MkdirAll(filepath.Join(outdir, outprefix), 0o755)
		}
		if outprefix == "" {
			outprefix = "other"
		}
		for p := range doneprefixes {
			if strings.HasPrefix(name, p) {
				doneprefix = p
				break
			}
		}
		if doneprefix == "" && len(name) > 10 && name[1] == '_' {
			doneprefix = name[:4]
			doneprefixes[doneprefix] = struct{}{}
			os.MkdirAll(filepath.Join(donedir, doneprefix), 0o755)
		}
		if doneprefix == "" {
			doneprefix = "other"
		}

		tmpname := filepath.Join(outdir, outprefix, ".tmp."+name)
		outname := filepath.Join(outdir, outprefix, name)

		donename := filepath.Join(donedir, doneprefix, name)

		failedname := filepath.Join(faileddir, name)

		cmd := exec.Command("ffmpeg",
			"-i", inname,
			"-c:v", "libsvtav1",
			"-cpu-used", "8",
			"-c:a", "copy",
			tmpname,
		)
		cmd.Stdout = stdout
		cmd.Stderr = stderr
		err = cmd.Run()
		if err != nil {
			os.RemoveAll(tmpname)
			os.Rename(inname, failedname)
			slog.Error("run ffmpeg", "name", inname, "err", err)
			continue
		}
		os.Rename(tmpname, outname)
		os.Rename(inname, donename)
		slog.Info("done, renamed", "name", name, "idx", i, "total_todo", len(todo))
	}
	return nil
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
