package httpencoding

import (
	"io"
	"net/http"
	"net/http/httptest"
	"testing"
)

var body = "hello world"

func TestHandler(t *testing.T) {
	svr := httptest.NewServer(Handler(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte(body))
	})))
	defer svr.Close()

	for _, coding := range []string{"zstd", "gzip"} {
		t.Run(coding, func(t *testing.T) {
			req, err := http.NewRequestWithContext(t.Context(), "GET", svr.URL, http.NoBody)
			if err != nil {
				t.Fatalf("create request: %v", err)
			}
			req.Header.Set("accept-encoding", coding)

			res, err := svr.Client().Do(req)
			if err != nil {
				t.Fatalf("send request: %v", err)
			}
			if res.StatusCode != 200 {
				t.Errorf("response code: %v", res.Status)
			}

			if got := res.Header.Get("content-encoding"); got != coding {
				t.Errorf("unexpected content-encoding: %v", got)
			}
			defer res.Body.Close()

			_, err = io.ReadAll(res.Body)
			if err != nil {
				t.Errorf("read response: %v", err)
			}
		})
	}
}
