package diff

import (
	"bytes"
	"os"
	"path/filepath"
	"testing"
)

func TestDiff(t *testing.T) {
	des, err := os.ReadDir("testdata")
	if err != nil {
		t.Fatal("read tesdata", err)
	}
	for _, de := range des {
		if !de.IsDir() {
			continue
		}
		t.Run(de.Name(), func(t *testing.T) {
			a, err := os.ReadFile(filepath.Join("testdata", de.Name(), "old"))
			if err != nil {
				t.Fatal("read old", err)
			}
			b, err := os.ReadFile(filepath.Join("testdata", de.Name(), "new"))
			if err != nil {
				t.Fatal("read new", err)
			}
			want, err := os.ReadFile(filepath.Join("testdata", de.Name(), "diff"))
			if err != nil {
				t.Fatal("read diff", err)
			}

			got := HistogramDiff(a, b, "old", "new")
			if !bytes.Equal(got, want) {
				t.Errorf("\n!!old:\n%s\n!!new:\n%s\n!!got:\n%s\n!!want:\n%s", a, b, got, want)
			}
			// err = os.WriteFile(filepath.Join("testdata", de.Name(), "got.diff"), got, 0o644)
			// if err != nil {
			// 	t.Fatal("write diff", err)
			// }
		})
	}
}
