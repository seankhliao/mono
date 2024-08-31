package main

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"time"

	"github.com/briandowns/spinner"
)

func writeRendered(stdout io.Writer, dst string, rendered map[string]*bytes.Buffer) error {
	spin := spinner.New(spinner.CharSets[39], 100*time.Millisecond, spinner.WithWriter(stdout))
	spin.FinalMSG = fmt.Sprintf("%3d/%3d written to dst %q\n", len(rendered), len(rendered), dst)
	spin.Start()
	defer spin.Stop()
	var idx int

	for p, buf := range rendered {
		idx++
		spin.Suffix = fmt.Sprintf("%3d/%3d writing to dst %q", idx, len(rendered), p)

		if p == singleKey {
			p = dst
		} else {
			p = filepath.Join(dst, p)
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
