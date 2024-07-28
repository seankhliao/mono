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

	"github.com/schollz/progressbar/v3"
	"golang.org/x/oauth2/google"
	firebasehosting "google.golang.org/api/firebasehosting/v1beta1"
)

func uploadFirebase(stdout io.Writer, conf ConfigFirebase, rendered map[string]*bytes.Buffer) error {
	ctx := context.TODO()

	done, bar := progress(stdout, len(rendered), "checksumming files")

	pathToHash := make(map[string]string)
	hashToGzip := make(map[string]io.Reader)
	for p, buf := range rendered {
		zipped := new(bytes.Buffer)
		summed := sha256.New()
		gzw := gzip.NewWriter(io.MultiWriter(zipped, summed))
		_, err := io.Copy(gzw, buf)
		if err != nil {
			return fmt.Errorf("gzip file: %w", err)
		}
		gzw.Close()
		sum := hex.EncodeToString(summed.Sum(nil))

		if p == singleKey {
			p = "index.html"
		}
		pathToHash["/"+p] = sum
		hashToGzip[sum] = zipped
		bar.Add(1)
	}
	<-done
	fmt.Fprintln(stdout)

	baseSteps := 6 // client, service, version, required, upload, release
	done, bar = progress(stdout, baseSteps, "preparing upload")

	httpClient, err := google.DefaultClient(ctx, "https://www.googleapis.com/auth/cloud-platform", "https://www.googleapis.com/auth/firebase")
	if err != nil {
		return fmt.Errorf("create http client: %w", err)
	}
	bar.Add(1)

	client, err := firebasehosting.NewService(ctx)
	if err != nil {
		return fmt.Errorf("create firebase client: %w", err)
	}
	bar.Add(1)

	bar.Describe("creating new version")
	site, version, err := createVersion(ctx, client, conf)
	if err != nil {
		return fmt.Errorf("create new version: %w", err)
	}
	bar.Add(1)

	bar.Describe("get required uploads")
	toUpload, uploadURL, err := getRequiredUploads(ctx, client, version, pathToHash)
	if err != nil {
		return fmt.Errorf("get required uploads: %w", err)
	}
	bar.ChangeMax(baseSteps + len(toUpload))
	bar.Add(1)

	bar.Describe("uploading files")
	err = uploadFiles(ctx, bar, client, httpClient, version, toUpload, uploadURL, hashToGzip)
	if err != nil {
		return err
	}
	bar.Add(1)

	bar.Describe("releasing")
	err = release(ctx, client, site, version)
	if err != nil {
		return err
	}
	bar.Add(1)

	<-done
	fmt.Fprintln(stdout)

	return nil
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

func uploadFiles(ctx context.Context, bar *progressbar.ProgressBar, client *firebasehosting.Service, httpClient *http.Client, version string, toUpload []string, uploadURL string, hashToGzip map[string]io.Reader) error {
	for _, uploadHash := range toUpload {
		endpoint := uploadURL + "/" + uploadHash
		req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, hashToGzip[uploadHash])
		if err != nil {
			return fmt.Errorf("create upload request: %w", err)
		}
		req.Header.Set("content-type", "application/octet-stream")
		res, err := httpClient.Do(req)
		if err != nil {
			return fmt.Errorf("upload file: %w", err)
		}
		if res.StatusCode != 200 {
			return errors.New(res.Status)
		}
		io.Copy(io.Discard, res.Body)
		res.Body.Close()

		bar.Add(1)
	}

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

func release(ctx context.Context, client *firebasehosting.Service, site, version string) error {
	_, err := client.Sites.Releases.Create(site, &firebasehosting.Release{}).VersionName(version).Context(ctx).Do()
	if err != nil {
		return fmt.Errorf("create reloease: %w", err)
	}

	return nil
}
