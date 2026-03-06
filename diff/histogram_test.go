package diff

import (
	"bytes"
	"fmt"
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
				t.Fatal("read old", err)
			}
			want, err := os.ReadFile(filepath.Join("testdata", de.Name(), "diff"))
			if err != nil {
				t.Fatal("read diff", err)
			}

			got := HistogramDiff(a, b, "old", "new")
			if !bytes.Equal(got, want) {
				fmt.Fprint(t.Output(), "\n!!old:\n", string(a), "\n!!new:\n", string(b))
				fmt.Fprint(t.Output(), "\n!!got:\n", string(got), "\n!!want:\n", string(want))
				t.Fail()
			}
			// err = os.WriteFile(filepath.Join("testdata", de.Name(), "got.diff"), got, 0o644)
			// if err != nil {
			// 	t.Fatal("write diff", err)
			// }
		})
	}
}
