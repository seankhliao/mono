package goreleases

import (
	_ "embed"
	"net/http"
	"net/http/httptest"
	"testing"
)

//go:embed testdata/response.json
var responseJSON []byte

func TestReleases(t *testing.T) {
	svr := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Write(responseJSON)
	}))
	defer svr.Close()

	releases, err := Releases(svr.Client(), t.Context(), svr.URL, false)
	if err != nil {
		t.Fatalf("unexpected error from releases: %v", err)
	}
	if len(releases) != 2 {
		t.Errorf("got releases %v, want 2", len(releases))
	}
	if releases[0].Version != "go1.24.0" {
		t.Errorf("releases[0] = %v, want go1.24.0", releases[0].Version)
	}
}
