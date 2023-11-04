package webstatic

import (
	"io/fs"
	"testing"
)

func TestEmbed(t *testing.T) {
	t.Run("favicon.ico", func(t *testing.T) {
		var found bool
		fs.WalkDir(StaticFS, ".", func(path string, d fs.DirEntry, err error) error {
			if path == "favicon.ico" {
				found = true
			}
			return nil
		})
		if !found {
			t.Error("favicon.ico not found in StaticFS")
		}
	})
}
