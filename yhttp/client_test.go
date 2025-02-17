package yhttp

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestUserAgent(t *testing.T) {
	uac := make(chan string, 1)
	svr := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		uac <- r.UserAgent()
	}))
	defer svr.Close()

	ua := "example"
	client := svr.Client()
	client.Transport = &UserAgent{
		Agent: ua,
		Next:  client.Transport,
	}

	res, err := client.Get(svr.URL)
	if err != nil {
		t.Errorf("get: %v", err)
	} else if res.StatusCode != 200 {
		t.Errorf("status: %v", res.Status)
	}
	defer res.Body.Close()

	if got := <-uac; got != ua {
		t.Errorf("user-agent: %v, want: %v", got, ua)
	}
}
