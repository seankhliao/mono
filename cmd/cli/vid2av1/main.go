package main

import (
	"fmt"
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

	fsys := os.DirFS(in)
	des, err := fs.ReadDir(fsys, ".")
	if err != nil {
		slog.Error("list src", "err", err)
		os.Exit(1)
	}
	var total int
	for _, de := range des {
		if de.IsDir() || strings.HasSuffix(de.Name(), ".jpg") {
			continue
		}
		total++
	}

	slog.Info("src total", "total", total)

	errf, err := os.Create("errors.log")
	if err != nil {
		slog.Error("create error log", "err", err)
		os.Exit(1)
	}
	defer errf.Close()

	var progress int
	err = fs.WalkDir(os.DirFS(in), ".", func(p string, d fs.DirEntry, err error) error {
		if err != nil || d.IsDir() || strings.HasSuffix(d.Name(), ".jpg") {
			return err
		}
		progress++
		fullname := filepath.Join(in, p)
		name := d.Name()
		outname := filepath.Join(out, name)
		_, err = os.Stat(outname)
		if err == nil {
			slog.Info("already exists, skipping", "src", fullname, "dst", outname, "progress", progress, "total", total)
			return nil
		}
		tmpout := filepath.Join(out, ".tmp."+name)
		cmd := exec.Command("ffmpeg", "-i", fullname, "-c:v", "libsvtav1", "-cpu-used", "8", "-c:a", "copy", tmpout)
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		err = cmd.Run()
		if err != nil {
			slog.Error("run ffmpeg", "err", err, "progress", progress, "total", total)
			fmt.Fprintln(errf, name, "err", err)
			return nil
		}
		os.Rename(tmpout, outname)
		slog.Info("done, renamed", "out", outname, "progress", progress, "total", total)
		return nil
	})
	if err != nil {
		slog.Error("walk", "err", err)
		os.Exit(1)
	}
}
