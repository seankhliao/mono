// goreleases is a wrapper for getting the current Go releases from go.dev/dl/?mode=json
package goreleases

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"strings"
)

const (
	ReleaseEndpoint = "https://go.dev/dl/?mode=json"
)

type Releases []Release

type Release struct {
	Version Version
	Stable  bool
	Files   []File
}

type File struct {
	Filename string
	OS       string
	Arch     string
	Version  Version
	SHA256   string
	Size     int
	Kind     string
}

type Version string

func (v Version) Parts() (major, minor, patch, rc, beta int) {
	// go1.2
	// go1.2beta3, go1.2rc3
	// go1.2.4
	maj, rem, _ := strings.Cut(string(v), ".") // go1 . 2...
	if maj == "go1" {
		major = 1
	}
	min, pat, found := strings.Cut(rem, ".") // 2 . 4
	if found {
		minor, _ = strconv.Atoi(min)
		patch, _ = strconv.Atoi(pat)
		return
	}
	min, r, found := strings.Cut(rem, "rc") // 2 rc 3
	if found {
		minor, _ = strconv.Atoi(min)
		rc, _ = strconv.Atoi(r)
		return
	}
	min, bet, found := strings.Cut(rem, "beta") // 2 beta 3
	if found {
		minor, _ = strconv.Atoi(min)
		beta, _ = strconv.Atoi(bet)
		return
	}
	minor, _ = strconv.Atoi(rem) // 2
	return
}

type Client struct {
	url    string
	client *http.Client
}

func New(c *http.Client, url string) *Client {
	if c == nil {
		c = http.DefaultClient
	}
	if url == "" {
		url = ReleaseEndpoint
	}
	return &Client{
		url:    url,
		client: c,
	}
}

func (c *Client) Releases(ctx context.Context, all bool) (Releases, error) {
	u := c.url
	if all {
		u += "&include=all"
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, u, nil)
	if err != nil {
		return nil, fmt.Errorf("goreleases prepare request: %w", err)
	}
	res, err := c.client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("goreleases do request: %w", err)
	}
	if res.StatusCode != 200 {
		return nil, fmt.Errorf("goreleases unexpected status: %v", res.Status)
	}
	defer res.Body.Close()
	b, err := io.ReadAll(res.Body)
	if err != nil {
		return nil, fmt.Errorf("goreleases read response: %w", err)
	}
	var releases Releases
	err = json.Unmarshal(b, &releases)
	if err != nil {
		return nil, fmt.Errorf("goreleases parse response: %w", err)
	}
	return releases, nil
}
