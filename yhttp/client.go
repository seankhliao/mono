package yhttp

import (
	"net/http"
	"runtime/debug"
	"sync"
)

type UserAgent struct {
	Agent string
	once  sync.Once
	Next  http.RoundTripper
}

func (u *UserAgent) RoundTrip(req *http.Request) (*http.Response, error) {
	u.once.Do(func() {
		if u.Agent == "" {
			bi, _ := debug.ReadBuildInfo()
			u.Agent = bi.Path
		}
	})
	req.Header.Set("user-agent", u.Agent)
	return u.Next.RoundTrip(req)
}

var _ http.RoundTripper = &UserAgent{}
