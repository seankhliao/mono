package main

import (
	"bytes"
	"context"
	"log/slog"
	"os"
	"path/filepath"
)

func writeRendered(ctx context.Context, lg *slog.Logger, out string, rendered map[string]*bytes.Buffer) error {
	for p, buf := range rendered {
		if p == singleKey {
			p = out
		} else {
			p = filepath.Join(out, p)
		}

		dir := filepath.Dir(p)
		err := os.MkdirAll(dir, 0o755)
		if err != nil {
			lg.LogAttrs(ctx, slog.LevelError, "create parent directories", slog.String("dir", dir), slog.String("error", err.Error()))
			return err
		}
		err = os.WriteFile(p, buf.Bytes(), 0o644)
		if err != nil {
			lg.LogAttrs(ctx, slog.LevelError, "write file", slog.String("path", p), slog.String("error", err.Error()))
			return err
		}
	}
	return nil
}
