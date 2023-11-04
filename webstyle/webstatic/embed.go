// webstatic is an filesystem for common static files needed across html pages.
package webstatic

import (
	"embed"
	"io"
	"io/fs"
	"net/http"
	"time"
)

var (
	//go:embed all:static
	staticFS embed.FS
	// StaticFS is everything in the static/ directory, with the first static/ stripped.
	StaticFS, _ = fs.Sub(staticFS, "static")
)

// Registrar is the interface used by Register,
// usually a http.ServeMux
type Registrar interface {
	HandleFunc(string, func(http.ResponseWriter, *http.Request))
}

// Registers the individual files with their matching paths.
func Register(reg Registrar) {
	t := time.Now()
	fs.WalkDir(StaticFS, ".", func(p string, d fs.DirEntry, err error) error {
		if d.IsDir() {
			return nil
		}
		reg.HandleFunc("/"+p, func(w http.ResponseWriter, r *http.Request) {
			f, err := StaticFS.Open(p)
			if err != nil {
				w.WriteHeader(http.StatusInternalServerError)
				return
			}
			rs, ok := f.(io.ReadSeeker)
			if !ok {
				w.WriteHeader(http.StatusInternalServerError)
				return
			}
			http.ServeContent(w, r, d.Name(), t, rs)
		})
		return nil
	})
}
