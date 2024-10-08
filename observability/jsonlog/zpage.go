package jsonlog

import (
	"io"
	"net/http"
	"sync"
)

var (
	_ io.Writer    = new(ZPage)
	_ http.Handler = new(ZPage)
)

type ZPage struct {
	mu  sync.Mutex
	idx int
	buf [][]byte
}

func NewZPage(maxLines int) *ZPage {
	return &ZPage{
		buf: make([][]byte, maxLines),
	}
}

func (z *ZPage) Write(p []byte) (int, error) {
	z.mu.Lock()
	defer z.mu.Unlock()
	z.buf[z.idx] = append(z.buf[z.idx][:0], p...)
	z.idx = (z.idx + 1) % len(z.buf)
	return len(p), nil
}

func (z *ZPage) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("content-type", "application/json")

	z.mu.Lock()
	defer z.mu.Unlock()
	for i := 0; i < len(z.buf); i++ {
		idx := (z.idx + i) % len(z.buf)
		if len(z.buf[idx]) == 0 {
			continue
		}
		w.Write(z.buf[idx])
	}
}
