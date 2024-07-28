package main

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"path/filepath"
)

func writeRendered(_ io.Writer, out string, rendered map[string]*bytes.Buffer) error {
	for p, buf := range rendered {
		if p == singleKey {
			p = out
		} else {
			p = filepath.Join(out, p)
		}

		dir := filepath.Dir(p)
		err := os.MkdirAll(dir, 0o755)
		if err != nil {
			return fmt.Errorf("create parent dirs: %w", err)
		}
		err = os.WriteFile(p, buf.Bytes(), 0o644)
		if err != nil {
			return fmt.Errorf("write file: %w", err)
		}
	}
	return nil
}
