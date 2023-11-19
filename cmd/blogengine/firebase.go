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
	"log/slog"
	"net/http"

	"golang.org/x/oauth2/google"
	firebasehosting "google.golang.org/api/firebasehosting/v1beta1"
)

func uploadFirebase(ctx context.Context, lg *slog.Logger, conf ConfigFirebase, rendered map[string]*bytes.Buffer) error {
	pathToHash := make(map[string]string)
	hashToGzip := make(map[string]io.Reader)
	for p, buf := range rendered {
		zipped := new(bytes.Buffer)
		summed := sha256.New()
		gzw := gzip.NewWriter(io.MultiWriter(zipped, summed))
		_, err := io.Copy(gzw, buf)
		if err != nil {
			lg.LogAttrs(ctx, slog.LevelError, "zip file", slog.String("file", p), slog.String("error", err.Error()))
			return err
		}
		gzw.Close()
		sum := hex.EncodeToString(summed.Sum(nil))

		if p == singleKey {
			p = "index.html"
		}
		pathToHash["/"+p] = sum
		hashToGzip[sum] = zipped
	}

	httpClient, err := google.DefaultClient(ctx, "https://www.googleapis.com/auth/cloud-platform", "https://www.googleapis.com/auth/firebase")
	if err != nil {
		return fmt.Errorf("create http client: %w", err)
	}

	client, err := firebasehosting.NewService(ctx)
	if err != nil {
		return fmt.Errorf("create firebase client: %w", err)
	}

	site, version, err := createVersion(ctx, lg, client, conf)
	if err != nil {
		return err
	}

	toUpload, uploadURL, err := getRequiredUploads(ctx, lg, client, version, pathToHash)
	if err != nil {
		return err
	}

	err = uploadFiles(ctx, lg, client, httpClient, version, toUpload, uploadURL, hashToGzip)
	if err != nil {
		return err
	}

	err = release(ctx, lg, client, site, version)
	if err != nil {
		return err
	}

	return nil
}

func createVersion(ctx context.Context, lg *slog.Logger, client *firebasehosting.Service, conf ConfigFirebase) (string, string, error) {
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
		lg.LogAttrs(ctx, slog.LevelError, "create version", slog.String("site", siteID), slog.String("error", err.Error()))
		return "", "", err
	}

	lg.LogAttrs(ctx, slog.LevelDebug, "crreated version", slog.String("version", version.Name))
	return siteID, version.Name, nil
}

func getRequiredUploads(ctx context.Context, lg *slog.Logger, client *firebasehosting.Service, version string, pathToHash map[string]string) ([]string, string, error) {
	populateResponse, err := client.Sites.Versions.PopulateFiles(version, &firebasehosting.PopulateVersionFilesRequest{
		Files: pathToHash,
	}).Context(ctx).Do()
	if err != nil {
		lg.LogAttrs(ctx, slog.LevelError, "populate files", slog.String("version", version), slog.String("error", err.Error()))
		return nil, "", err
	}

	lg.LogAttrs(ctx, slog.LevelInfo, "got required uploads", slog.Int("to_upload", len(populateResponse.UploadRequiredHashes)))
	return populateResponse.UploadRequiredHashes, populateResponse.UploadUrl, nil
}

func uploadFiles(ctx context.Context, lg *slog.Logger, client *firebasehosting.Service, httpClient *http.Client, version string, toUpload []string, uploadURL string, hashToGzip map[string]io.Reader) error {
	lg.LogAttrs(ctx, slog.LevelInfo, "uploading required files", slog.Int("to_upload", len(toUpload)), slog.Int("total", len(hashToGzip)))
	for _, uploadHash := range toUpload {
		endpoint := uploadURL + "/" + uploadHash
		req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, hashToGzip[uploadHash])
		if err != nil {
			lg.LogAttrs(ctx, slog.LevelError, "create request", slog.String("uploadHash", uploadHash), slog.String("error", err.Error()))
			return err
		}
		req.Header.Set("content-type", "application/octet-stream")
		res, err := httpClient.Do(req)
		if err != nil {
			lg.LogAttrs(ctx, slog.LevelError, "upload", slog.String("uploadHash", uploadHash), slog.String("error", err.Error()))
			return err
		}
		if res.StatusCode != 200 {
			lg.LogAttrs(ctx, slog.LevelError, "non 200 status", slog.String("uploadHash", uploadHash), slog.String("status", res.Status))
			return errors.New(res.Status)
		}
		io.Copy(io.Discard, res.Body)
		res.Body.Close()
	}

	patchResponse, err := client.Sites.Versions.Patch(version, &firebasehosting.Version{
		Status: "FINALIZED",
	}).Context(ctx).Do()
	if err != nil {
		lg.LogAttrs(ctx, slog.LevelError, "patch to finalize", slog.String("version", version), slog.String("error", err.Error()))
		return err
	}
	if patchResponse.Status != "FINALIZED" {
		lg.LogAttrs(ctx, slog.LevelError, "status not finalized", slog.String("error", err.Error()))
		return errors.New(patchResponse.Status)
	}

	lg.LogAttrs(ctx, slog.LevelDebug, "finalized version", slog.String("version", version))
	return nil
}

func release(ctx context.Context, lg *slog.Logger, client *firebasehosting.Service, site, version string) error {
	_, err := client.Sites.Releases.Create(site, &firebasehosting.Release{}).VersionName(version).Context(ctx).Do()
	if err != nil {
		lg.LogAttrs(ctx, slog.LevelError, "create reloease", slog.String("version", version), slog.String("error", err.Error()))
		return err
	}

	lg.LogAttrs(ctx, slog.LevelDebug, "released version", slog.String("version", version))
	return nil
}
