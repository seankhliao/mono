package homepage

import (
	"bytes"
	"io"
	"net/http/httptest"
	"testing"

	"go.seankhliao.com/mono/yo11y"
)

func TestHomepage(t *testing.T) {
	host := "host.example.com"
	app, err := New(t.Context(), Config{host}, yo11y.O11y{})
	if err != nil {
		t.Fatalf("create app: %v", err)
	}
	svr := httptest.NewServer(app)
	defer svr.Close()

	res, err := svr.Client().Get(svr.URL)
	if err != nil {
		t.Fatalf("get: %v", err)
	} else if res.StatusCode != 200 {
		t.Errorf("status: %v", res.Status)
	}
	defer res.Body.Close()
	b, err := io.ReadAll(res.Body)
	if err != nil {
		t.Fatalf("read body: %v", err)
	}

	if !bytes.Contains(b, []byte("<h1>"+host+"</h1>")) {
		t.Errorf("missing host in content")
	}
}
