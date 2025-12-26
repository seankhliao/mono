package main

import (
	"bytes"
	"compress/gzip"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"net/http"
	"slices"
	"sync"
	"time"

	"github.com/briandowns/spinner"
	"golang.org/x/oauth2/google"
	firebasehosting "google.golang.org/api/firebasehosting/v1beta1"
)

func uploadFirebase(stdout io.Writer, conf ConfigFirebase, rendered map[string]*bytes.Buffer, uploadPreview bool) error {
	ctx := context.TODO()

	pathToHash, hashToGzip, err := hashAndGzip(rendered)
	if err != nil {
		return fmt.Errorf("prepare file hash: %w", err)
	}

	spin := spinner.New(spinner.CharSets[39], 100*time.Millisecond, spinner.WithWriter(stdout))
	spin.Start()
	defer spin.Stop()

	spin.Suffix = "creating http client"
	httpClient, err := google.DefaultClient(ctx, "https://www.googleapis.com/auth/cloud-platform", "https://www.googleapis.com/auth/firebase")
	if err != nil {
		return fmt.Errorf("create http client: %w", err)
	}

	spin.Suffix = "creating firebase client"
	client, err := firebasehosting.NewService(ctx)
	if err != nil {
		return fmt.Errorf("create firebase client: %w", err)
	}

	spin.Suffix = "creating new website version"
	site, version, err := createVersion(ctx, client, conf)
	if err != nil {
		return fmt.Errorf("create new version: %w", err)
	}

	spin.Suffix = "getting required uploads"
	toUpload, uploadURL, err := getRequiredUploads(ctx, client, version, pathToHash)
	if err != nil {
		return fmt.Errorf("get required uploads: %w", err)
	}

	err = uploadFiles(ctx, client, httpClient, version, toUpload, uploadURL, hashToGzip, spin)
	if err != nil {
		return err
	}

	spin.Suffix = "releasing..."
	u, err := release(ctx, client, site, version, uploadPreview)
	if err != nil {
		return err
	}

	spin.FinalMSG = fmt.Sprintf("released new version with %d changed files\n", len(toUpload))
	if u != "" {
		spin.FinalMSG = fmt.Sprintf("released new version with %d changed files: %s", len(toUpload), u)
	}
	spin.Stop()

	fmt.Println()
	printUploaded(pathToHash, toUpload)

	return nil
}

func hashAndGzip(rendered map[string]*bytes.Buffer) (map[string]string, map[string]io.Reader, error) {
	spin := spinner.New(spinner.CharSets[39], 100*time.Millisecond)
	spin.FinalMSG = fmt.Sprintf("%3d files checksummed\n", len(rendered))
	spin.Start()
	defer spin.Stop()
	var idx int

	pathToHash := make(map[string]string)
	hashToGzip := make(map[string]io.Reader)
	for p, buf := range rendered {
		idx++
		spin.Suffix = fmt.Sprintf("%3d/%3d checksumming files", idx, len(rendered))
		zipped := new(bytes.Buffer)
		summed := sha256.New()
		gzw := gzip.NewWriter(io.MultiWriter(zipped, summed))
		_, err := io.Copy(gzw, buf)
		if err != nil {
			return nil, nil, fmt.Errorf("gzip file: %w", err)
		}
		gzw.Close()
		sum := hex.EncodeToString(summed.Sum(nil))

		if p == singleKey {
			p = "index.html"
		}
		pathToHash["/"+p] = sum
		hashToGzip[sum] = zipped
	}

	return pathToHash, hashToGzip, nil
}

func printUploaded(pathToHash map[string]string, toUpload []string) {
	uploaded := make([]string, 0, len(toUpload))
	hashToPath := make(map[string]string, len(pathToHash))
	for k, v := range pathToHash {
		hashToPath[v] = k
	}
	for _, hash := range toUpload {
		uploaded = append(uploaded, hashToPath[hash])
	}
	slices.Sort(uploaded)
	for _, f := range uploaded {
		fmt.Println("\t", f)
	}
}

func createVersion(ctx context.Context, client *firebasehosting.Service, conf ConfigFirebase) (string, string, error) {
	servingConf := &firebasehosting.ServingConfig{
		CleanUrls:             true,
		TrailingSlashBehavior: "ADD",
	}
	for _, header := range conf.Headers {
		servingConf.Headers = append(servingConf.Headers, &firebasehosting.Header{
			Glob:    header.Glob,
			Headers: header.Headers,
		})
	}
	for _, redirect := range conf.Redirects {
		servingConf.Redirects = append(servingConf.Redirects, &firebasehosting.Redirect{
			Glob:       redirect.Glob,
			Location:   redirect.Location,
			StatusCode: int64(redirect.StatusCode),
		})
	}

	siteID := "sites/" + conf.SiteID
	version, err := client.Sites.Versions.Create(siteID, &firebasehosting.Version{
		Config: servingConf,
	}).Context(ctx).Do()
	if err != nil {
		return "", "", err
	}

	return siteID, version.Name, nil
}

func getRequiredUploads(ctx context.Context, client *firebasehosting.Service, version string, pathToHash map[string]string) ([]string, string, error) {
	populateResponse, err := client.Sites.Versions.PopulateFiles(version, &firebasehosting.PopulateVersionFilesRequest{
		Files: pathToHash,
	}).Context(ctx).Do()
	if err != nil {
		return nil, "", fmt.Errorf("populate files: %w", err)
	}

	return populateResponse.UploadRequiredHashes, populateResponse.UploadUrl, nil
}

func uploadFiles(ctx context.Context, client *firebasehosting.Service, httpClient *http.Client, version string, toUpload []string, uploadURL string, hashToGzip map[string]io.Reader, spin *spinner.Spinner) error {
	maxUploads := 10
	sem := make(chan struct{}, maxUploads)
	errc := make(chan error, 1)
	var wg sync.WaitGroup
	for idx, uploadHash := range toUpload {
		sem <- struct{}{}
		spin.Suffix = fmt.Sprintf("%3d/%3d uploading files", idx+1, len(toUpload))
		wg.Add(1)
		go func() {
			defer wg.Done()
			defer func() { <-sem }()

			endpoint := uploadURL + "/" + uploadHash
			req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, hashToGzip[uploadHash])
			if err != nil {
				select {
				case errc <- fmt.Errorf("create upload request: %w", err):
				default:
				}
				return
			}
			req.Header.Set("content-type", "application/octet-stream")
			res, err := httpClient.Do(req)
			if err != nil {
				select {
				case errc <- fmt.Errorf("execute upload request: %w", err):
				default:
				}
				return
			}
			defer res.Body.Close()
			if res.StatusCode != 200 {
				select {
				case errc <- fmt.Errorf("upload request response: %v", res.StatusCode):
				default:
				}
			}
		}()
	}

	wg.Wait()
	close(errc)
	err, ok := <-errc
	if ok && err != nil {
		return fmt.Errorf("upload: %w", err)
	}

	spin.Suffix = "finalizing upload"
	patchResponse, err := client.Sites.Versions.Patch(version, &firebasehosting.Version{
		Status: "FINALIZED",
	}).Context(ctx).Do()
	if err != nil {
		return fmt.Errorf("finalize: %w", err)
	}
	if patchResponse.Status != "FINALIZED" {
		return errors.New(patchResponse.Status)
	}

	return nil
}

func release(ctx context.Context, client *firebasehosting.Service, site, version string, uploadPreview bool) (string, error) {
	channel := site + "/channels/live"
	if uploadPreview {
		channel = site + "/channels/preview"
	}
	ch, err := client.Sites.Channels.Get(channel).Context(ctx).Do()
	if uploadPreview && err != nil {
		ch, err = client.Sites.Channels.Create(site, &firebasehosting.Channel{
			ExpireTime: time.Now().Add(12 * time.Hour).Format(time.RFC3339),
			Name:       channel,
		}).ChannelId("preview").Context(ctx).Do()
	}
	if err != nil {
		return "", fmt.Errorf("get channel %s: %w", channel, err)
	}

	_, err = client.Sites.Releases.Create(channel, &firebasehosting.Release{}).VersionName(version).Context(ctx).Do()
	if err != nil {
		return "", fmt.Errorf("create reloease: %w", err)
	}

	return ch.Url, nil
}
