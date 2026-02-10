// httpencoding does on-the-fly zstd or gzip compression of the responses of the wrapped handlers.
// The handlers it wraps should not do their own compression.
package httpencoding

import (
	"compress/gzip"
	"io"
	"net/http"
	"strconv"
	"strings"

	"github.com/klauspost/compress/zstd"
)

// Handler wraps the given handler to return write responses in gzip or zstd content-encoding
// if the incoming request has the corresponding accept-encoding header.
func Handler(h http.Handler) http.Handler {
	return http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
		var acceptGz, acceptZstd float64
		for encQ := range strings.SplitSeq(r.Header.Get("accept-encoding"), ",") {
			enc, qkv, ok := strings.Cut(encQ, ";")
			var q float64 = 1
			if ok {
				litq, qs, ok := strings.Cut(qkv, "=")
				if litq == "q" && ok {
					q, _ = strconv.ParseFloat(qs, 64)
				}
			}
			switch strings.TrimSpace(enc) {
			case "gzip":
				acceptGz = q
			case "zstd":
				acceptZstd = q
			}
		}

		if acceptGz == 0 && acceptZstd == 0 {
			h.ServeHTTP(rw, r)
		} else if acceptGz > acceptZstd {
			nrw := newGzip(rw)
			defer nrw.Flush()
			rw.Header().Set("content-encoding", "gzip")
			h.ServeHTTP(nrw, r)
		} else {
			nrw := newZstd(rw)
			defer nrw.Flush()
			rw.Header().Set("content-encoding", "zstd")
			h.ServeHTTP(nrw, r)
		}
	})
}

type encoder interface {
	io.Writer
	Flush() error
}

type responseWriter struct {
	http.ResponseWriter
	e encoder
}

func newGzip(rw http.ResponseWriter) *responseWriter {
	return &responseWriter{
		rw,
		gzip.NewWriter(rw),
	}
}

func newZstd(rw http.ResponseWriter) *responseWriter {
	e, _ := zstd.NewWriter(rw)
	return &responseWriter{
		rw,
		e,
	}
}

func (r *responseWriter) Flush() {
	r.e.Flush()
	if flusher, ok := r.ResponseWriter.(http.Flusher); ok {
		flusher.Flush()
	}
}

func (r *responseWriter) Write(b []byte) (int, error) {
	return r.e.Write(b)
}

func (r *responseWriter) Unwrap() http.ResponseWriter {
	return r.ResponseWriter
}
