// goreleases is a wrapper for getting the current Go releases from
// https://go.dev/dl/?mode=json
package goreleases

import (
	"context"
	"fmt"
	"io"
	"net/http"

	"github.com/go-json-experiment/json"
)

const (
	ReleaseEndpoint = "https://go.dev/dl/?mode=json"
)

type Release struct {
	Version string `json:"version"`
	Stable  bool   `json:"stable"`
	Files   []File `json:"files"`
}

type File struct {
	Filename string `json:"filename"`
	OS       string `json:"os"`
	Arch     string `json:"arch"`
	Version  string `json:"version"`
	SHA256   string `json:"sha256"`
	Size     int    `json:"size"`
	Kind     string `json:"kind"`
}

func Releases(client *http.Client, ctx context.Context, endpoint string, all bool) ([]Release, error) {
	if endpoint == "" {
		endpoint = ReleaseEndpoint
	}
	if all {
		endpoint += "&include=all"
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return nil, fmt.Errorf("goreleases prepare request: %w", err)
	}
	res, err := client.Do(req)
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
	var releases []Release
	err = json.Unmarshal(b, &releases)
	if err != nil {
		return nil, fmt.Errorf("goreleases parse response: %w", err)
	}
	return releases, nil
}
